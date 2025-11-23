from fastapi import FastAPI, UploadFile, File, Form, BackgroundTasks
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
import json
import uuid
import os
from pathlib import Path
from processor import process_video

app = FastAPI(title="Auto Caption Server")

# CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Storage
UPLOAD_DIR = Path("uploads")
OUTPUT_DIR = Path("outputs")
UPLOAD_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)

# Job status storage (in production, use Redis)
jobs = {}

@app.post("/upload")
async def upload_video(
    background_tasks: BackgroundTasks,
    video: UploadFile = File(...),
    captions: str = Form(...),
    aspect_ratio: str = Form(...),
    template: str = Form("classic")  # Default to classic template
):
    """Upload video and captions for processing"""
    job_id = str(uuid.uuid4())
    
    # Save uploaded video
    video_path = UPLOAD_DIR / f"{job_id}.mp4"
    with open(video_path, "wb") as f:
        content = await video.read()
        f.write(content)
    
    # Parse captions
    captions_data = json.loads(captions)
    
    # Initialize job status
    jobs[job_id] = {"status": "queued", "progress": 0}
    
    # Process in background
    background_tasks.add_task(
        process_video,
        str(video_path),
        captions_data,
        aspect_ratio,
        str(OUTPUT_DIR / f"{job_id}.mp4"),
        job_id,
        jobs,
        template  # Pass template to processor
    )
    
    return {"job_id": job_id, "status": "queued"}

@app.get("/templates")
async def get_templates():
    """Get available caption templates"""
    from processor import TEMPLATES
    return {
        "templates": [
            {"id": key, "name": val["name"]} 
            for key, val in TEMPLATES.items()
        ]
    }

@app.get("/status/{job_id}")
async def get_status(job_id: str):
    """Check processing status"""
    if job_id not in jobs:
        return {"error": "Job not found"}, 404
    return jobs[job_id]

@app.get("/download/{job_id}")
async def download_video(job_id: str):
    """Download processed video"""
    if job_id not in jobs:
        return {"error": "Job not found"}, 404
    
    if jobs[job_id]["status"] != "completed":
        return {"error": "Video not ready"}, 400
    
    output_path = OUTPUT_DIR / f"{job_id}.mp4"
    return FileResponse(
        output_path,
        media_type="video/mp4",
        filename="captioned_video.mp4"
    )

@app.on_event("startup")
async def startup():
    print("🚀 Server started! Visit http://localhost:8000/docs for API docs")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
