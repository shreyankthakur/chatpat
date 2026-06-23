## Crash-hardening steps (frontend)

- [ ] Add global Flutter error guards in `frontend/lib/main.dart` (runZonedGuarded + FlutterError.onError)
- [ ] Harden `WebSocketService` message decode + handler invocation (`frontend/lib/services/websocket_service.dart`)
- [ ] Harden `ChatScreen` WebSocket message parsing + polling loop + avoid overlapping loads (`frontend/lib/screens/chat_screen.dart`)
- [ ] Harden `CallService` WebRTC init + offer/answer/ice handlers with try/catch (`frontend/lib/services/call_service.dart`)
- [ ] Harden `BackgroundService` reconnection recursion + ensure timers never throw uncaught (`frontend/lib/services/background_service.dart`)
- [ ] Run `flutter analyze` and verify build

