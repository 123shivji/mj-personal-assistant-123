import os
from typing import List, Dict
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from openai import OpenAI

load_dotenv()
app = FastAPI(title="MJ Assistant API")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True,
                   allow_methods=["*"], allow_headers=["*"])

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY")) if os.getenv("OPENAI_API_KEY") else None
history: List[Dict[str, str]] = []

SYSTEM_PROMPT = '''
You are MJ, a warm, emotionally considerate female-voiced personal AI companion.
Speak naturally, mainly in Hindi/Hinglish matching the user's language.
Be friendly, thoughtful, respectful and conversational, not robotic.
Try to recognize emotional cues, acknowledge feelings without claiming certainty,
and ask gentle follow-up questions when useful. Never pretend to be human or
claim to literally feel emotions. Be honest about uncertainty.
Keep spoken answers concise unless the user asks for detail.
'''

class ChatRequest(BaseModel):
    message: str

@app.get("/health")
def health():
    return {"ok": True, "assistant": "MJ"}

@app.post("/chat")
def chat(req: ChatRequest):
    if not client:
        return {"reply": "MJ का AI अभी सेटअप नहीं हुआ है। backend की .env फाइल में OpenAI API key डालो।"}
    history.append({"role": "user", "content": req.message})
    messages = [{"role": "system", "content": SYSTEM_PROMPT}] + history[-12:]
    try:
        result = client.chat.completions.create(
            model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
            messages=messages, temperature=0.8)
        reply = result.choices[0].message.content or "मैं सुन रही हूँ। थोड़ा और बताओ।"
        history.append({"role": "assistant", "content": reply})
        return {"reply": reply}
    except Exception:
        return {"reply": "माफ़ करना, अभी कनेक्शन में दिक्कत आ रही है। थोड़ी देर बाद फिर कोशिश करें।"}
