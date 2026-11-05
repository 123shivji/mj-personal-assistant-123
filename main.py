import os
import secrets
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel
from openai import OpenAI

app = FastAPI(title="MJ Personal Assistant")

class ChatRequest(BaseModel):
    message: str

@app.get("/health")
def health():
    return {"status": "ok", "service": "MJ"}

@app.post("/chat")
def chat(
    req: ChatRequest,
    authorization: str | None = Header(default=None)
):
    token = os.environ.get("MJ_ACCESS_TOKEN")
    
    if not token:
        raise HTTPException(
            status_code=503,
            detail="Server security is not configured"
        )

    expected = "Bearer " + token

    if not authorization or not secrets.compare_digest(
        authorization, expected
    ):
        raise HTTPException(
            status_code=401,
            detail="Unauthorized"
        )

    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        raise HTTPException(
            status_code=503,
            detail="AI key is not configured"
        )

    try:
        client = OpenAI(api_key=api_key)
        response = client.responses.create(
            model=os.environ.get("OPENAI_MODEL", "gpt-4.1-mini"),
            instructions=(
                "You are MJ, a warm and respectful female-style "
                "personal assistant. Speak naturally in Hindi or "
                "the user's language. Be honest about your abilities. "
                "Never claim to perform actions you did not perform. "
                "Ask permission before sensitive actions."
            ),
            input=req.message
        )
        return {"reply": response.output_text}

    except Exception:
        raise HTTPException(
            status_code=502,
            detail="AI service temporarily unavailable"
        )
      
