from fastapi import FastAPI, UploadFile, File, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import requests
from bs4 import BeautifulSoup
import os
import re
import json
import base64
from typing import Optional, List
from pathlib import Path
from uuid import uuid4
from pydantic import BaseModel
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()
RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

app = FastAPI()

# 1. CORS 설정 수정 
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True, # 쿠키/인증 헤더 허용
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(UPLOAD_DIR)), name="uploads")

client = OpenAI(api_key=OPENAI_API_KEY)

# --- [AI 분석 핵심 함수: 제목 생성 기능 추가] ---
def get_ai_summary(content: str):
    if not content or content == "내용 없음" or len(content.strip()) < 10:
        return "제목 없음", "정보를 추출할 본문이 부족합니다.", "기타", ["내용부족"]

    try:
        # [수정] AI에게 '제목(title)'까지 지으라고 명시적으로 지시합니다.
        prompt = f"""
        너는 콘텐츠 분석 전문가야. 아래 본문을 한국어로 분석해서 반드시 JSON만 반환해.
        [규칙]
        1. title: 본문 내용을 대표하는 매력적인 제목 (15자 내외)
        2. summary: 핵심 내용을 "• 항목: 설명" 형식의 리스트로 작성.
        3. category: 장소, 자기계발, 쇼핑, 운동, 기타 중 하나만 선택.
        4. tags: 키워드 2~3개 배열.
        본문: {content[:4000]}
        """
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[{"role": "system", "content": "JSON 출력기"}, {"role": "user", "content": prompt}],
            temperature=0,
            response_format={"type": "json_object"}
        )
        res = json.loads(response.choices[0].message.content.strip())
        return res.get("title", "분석된 제목"), res.get("summary", ""), res.get("category", "기타"), res.get("tags", [])
    except:
        return "분석 실패", "내용 요약 중 에러 발생", "기타", ["에러"]

# --- [기존 데이터 추출 로직 유지] ---
def get_instagram_data(url: str):
    headers = {"x-rapidapi-key": RAPIDAPI_KEY or "", "x-rapidapi-host": "instagram-scraper-stable-api.p.rapidapi.com"}
    match = re.search(r"/(?:p|reel|reels)/([A-Za-z0-9_-]+)", url)
    media_code = match.group(1) if match else ""
    try:
        res = requests.get("https://instagram-scraper-stable-api.p.rapidapi.com/get_media_data_v2.php", headers=headers, params={"media_code": media_code}, timeout=10).json()
        item = (res.get("data") or res.get("items") or [res])[0]
        content = item.get("edge_media_to_caption", {}).get("edges", [{}])[0].get("node", {}).get("text") or item.get("caption", {}).get("text") or "내용 없음"
        thumbnail = item.get("display_url") or item.get("thumbnail_url") or ""
        return "Instagram 콘텐츠", content, thumbnail
    except: return "Instagram 콘텐츠", "내용 없음", ""

def get_web_data(url: str):
    try:
        res = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=10)
        soup = BeautifulSoup(res.text, "html.parser")
        title = soup.title.string.strip() if soup.title else "제목 없음"
        body = soup.body.get_text(separator="\n", strip=True)[:3000]
        og = soup.find("meta", property="og:image")
        return title, body, (og.get("content") if og else "")
    except: return "제목 없음", "내용 없음", ""

def extract_image_text(base64_image: str):
    res = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": [{"type": "text", "text": "텍스트 추출"}, {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}}]}],
        temperature=0
    )
    return res.choices[0].message.content

# --- [API 엔드포인트: 요청 규격 반영] ---

@app.post("/analyze")
def analyze_url(url: str):
    _, content, thumb = get_instagram_data(url) if "instagram.com" in url else get_web_data(url)
    ai_t, summ, cat, tags = get_ai_summary(content)
    # 응답 필드 통일: title, summary, category, tags, thumbnail, originalText
    return {"status": "ACTIVE", "url": url, "title": ai_t, "summary": summ, "category": cat, "tags": tags, "thumbnail": thumb, "originalText": content}

@app.post("/analyze/image")
async def analyze_image(files: List[UploadFile] = File(...)):
    all_text = ""
    for i, file in enumerate(files, 1):
        base64_img = base64.b64encode(await file.read()).decode("utf-8")
        all_text += f"\n[이미지 {i}]\n{extract_image_text(base64_img)}"
    
    # [수정] 고정 제목 대신 AI가 텍스트를 기반으로 제목을 지어줍니다.
    ai_t, summ, cat, tags = get_ai_summary(all_text)
    return {"status": "ACTIVE", "title": ai_t, "summary": summ, "category": cat, "tags": tags, "originalText": all_text}

@app.post("/analyze/complex")
async def analyze_complex(url: str, files: List[UploadFile] = File(...)):
    _, url_c, thumb = get_instagram_data(url) if "instagram.com" in url else get_web_data(url)
    img_text = ""
    for i, file in enumerate(files, 1):
        base64_img = base64.b64encode(await file.read()).decode("utf-8")
        img_text += f"\n[이미지 {i}]\n{extract_image_text(base64_img)}"
    
    combined = f"[링크 정보]\n{url_c}\n\n[이미지 텍스트]\n{img_text}"
    ai_t, summ, cat, tags = get_ai_summary(combined)
    return {"status": "ACTIVE", "url": url, "title": ai_t, "summary": summ, "category": cat, "tags": tags, "thumbnail": thumb, "originalText": combined}

@app.post("/upload/images")
async def upload_images(request: Request, files: List[UploadFile] = File(...)):
    urls = []
    for file in files:
        contents = await file.read()
        filename = f"{uuid4().hex}{os.path.splitext(file.filename or '')[1].lower() or '.jpg'}"
        with open(UPLOAD_DIR / filename, "wb") as f: f.write(contents)
        urls.append(f"{str(request.base_url).rstrip('/')}/uploads/{filename}")
    return {"status": "success", "imageUrls": urls}

@app.get("/")
def health(): return {"status": "ok"}