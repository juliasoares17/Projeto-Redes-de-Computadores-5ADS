import uvicorn
from fastapi import APIRouter, FastAPI, WebSocket, WebSocketDisconnect
from fastapi.websockets import WebSocketState


class Chat:
    def __init__(self):
        self.connections: list[WebSocket] = []

    def enter_chat(self, ws: WebSocket):
        self.connections.append(ws)

    def leave_chat(self, ws: WebSocket):
        self.connections.remove(ws)

    async def broadcast(self, name: str, message: str):
        sub = {
                "name": name,
                "message": message
            }
        print(f"bradcasting subject: {sub}")
        for conn in self.connections:
            await conn.send_json(sub)

def create_app():
    app = FastAPI()

    router = APIRouter()

    chat_room = Chat()

    @router.websocket("/chat/{name}")
    async def chat_socket(name: str, ws: WebSocket):
        try:
            await ws.accept()
            chat_room.enter_chat(ws)
            await chat_room.broadcast("System", f"{name} has entered the chat room")
            while ws.client_state == WebSocketState.CONNECTED:
                message = await ws.receive_text()
                await chat_room.broadcast(name, message)

            chat_room.leave_chat(ws)
        
        except WebSocketDisconnect:
            print("Erro: websocket disconnect")
            chat_room.leave_chat(ws)
            await chat_room.broadcast("System", f"{name} has left the chat room")

    app.include_router(router)

    return app


if __name__ == "__main__":
    uvicorn.run("live_chat:create_app", host="0.0.0.0", port=8000, log_level="info", factory=True)
