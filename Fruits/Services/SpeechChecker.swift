import Foundation
import os
import Speech

enum SpeechCheckStatus: Equatable, Sendable {
    /// On-device recognition is ready.
    case available
    /// Supported, but the user hasn't been asked yet.
    case needsPermission
    /// The user (or a restriction) turned speech recognition off.
    case denied
    /// This device can't recognize English offline.
    case unsupported
}

/// Turns a recording into text. A protocol so practice logic can be tested without the Speech framework.
@MainActor
protocol SpeechChecking: AnyObject {
    var status: SpeechCheckStatus { get }
    func requestAccess() async -> SpeechCheckStatus
    /// Returns transcriptions from best to worst guess.
    func transcribe(_ url: URL, hints: [String]) async throws -> [String]
}

/// Speech recognition that only ever runs on the device. A child's voice is never sent to a server;
/// when offline recognition isn't available, practice falls back to "record and compare".
@MainActor
final class SpeechChecker: SpeechChecking {
    enum CheckError: Error { case unavailable, timedOut }

    private let recognizer: SFSpeechRecognizer?

    init(languageCode: String) {
        recognizer = [languageCode, "en-US"]
            .lazy
            .compactMap { SFSpeechRecognizer(locale: Locale(identifier: $0)) }
            .first { $0.supportsOnDeviceRecognition }
    }

    var status: SpeechCheckStatus {
        guard let recognizer else { return .unsupported }
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: return recognizer.isAvailable ? .available : .unsupported
        case .notDetermined: return .needsPermission
        default: return .denied
        }
    }

    func requestAccess() async -> SpeechCheckStatus {
        guard recognizer != nil else { return .unsupported }
        if SFSpeechRecognizer.authorizationStatus() == .notDetermined {
            _ = await withCheckedContinuation { (continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
                SFSpeechRecognizer.requestAuthorization { @Sendable status in
                    continuation.resume(returning: status)
                }
            }
        }
        return status
    }

    func transcribe(_ url: URL, hints: [String]) async throws -> [String] {
        guard let recognizer, status == .available else { throw CheckError.unavailable }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false
        request.contextualStrings = hints
        request.taskHint = .search

        let handle = RecognitionHandle()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[String], Error>) in
                handle.begin(continuation)
                // The result handler runs on a background queue, so it must not inherit main-actor isolation.
                let task = recognizer.recognitionTask(with: request) { @Sendable result, error in
                    if let result, result.isFinal {
                        handle.finish(.success(result.transcriptions.map(\.formattedString)))
                    } else if let error {
                        handle.finish(.failure(error))
                    }
                }
                handle.attach(task)
                // Safety net: recognition of a few seconds of audio should never take this long.
                Task {
                    try? await Task.sleep(for: .seconds(10))
                    handle.finish(.failure(CheckError.timedOut))
                }
            }
        } onCancel: {
            handle.finish(.failure(CancellationError()))
        }
    }
}

/// Resumes the continuation exactly once, whichever of result, error, timeout or cancellation comes first.
private final class RecognitionHandle: Sendable {
    private struct State {
        var continuation: CheckedContinuation<[String], Error>?
        var task: SFSpeechRecognitionTask?
        var finished = false
    }

    private let state = OSAllocatedUnfairLock<State>(uncheckedState: State())

    func begin(_ continuation: CheckedContinuation<[String], Error>) {
        let alreadyFinished = state.withLockUnchecked { state -> Bool in
            if state.finished { return true }
            state.continuation = continuation
            return false
        }
        if alreadyFinished { continuation.resume(throwing: CancellationError()) }
    }

    func attach(_ task: SFSpeechRecognitionTask) {
        let cancelNow = state.withLockUnchecked { state -> Bool in
            state.task = task
            return state.finished
        }
        if cancelNow { task.cancel() }
    }

    func finish(_ result: Result<[String], Error>) {
        let pending = state.withLockUnchecked { state -> (CheckedContinuation<[String], Error>?, SFSpeechRecognitionTask?)? in
            guard !state.finished else { return nil }
            state.finished = true
            defer { state.continuation = nil; state.task = nil }
            return (state.continuation, state.task)
        }
        guard let (continuation, task) = pending else { return }
        if case .failure = result { task?.cancel() }
        continuation?.resume(with: result)
    }
}
