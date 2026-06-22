# TODO

- [x] Add connection timeout + detailed diagnostics to Flutter websocket services (chat + call)


- [x] Fix backend ASGI websocket middleware to use AuthMiddlewareStack (and keep token middleware) so websocket handshake doesn’t fail

- [ ] Ensure middleware/token parsing is robust for Railway proxy
- [ ] Restart and verify by attempting WS connect
- [ ] If still failing, check Railway logs for daphne/ASGI websocket routing and allowed WebSocket upgrade

