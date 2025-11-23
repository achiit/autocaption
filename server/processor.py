import subprocess
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pathlib import Path

# Professional Caption Templates (CapCut-style)
TEMPLATES = {
    "classic": {
        "name": "Classic",
        "font_size": 52,
        "bg_color": (0, 0, 0, 140),  # Lighter black background
        "text_color": (255, 255, 255, 255),
        "highlight_color": (255, 255, 0, 255),
        "radius": 15,
        "padding": 40,
        "has_glow": False,
        "stroke_width": 0,
    },
    "neon": {
        "name": "Neon Glow",
        "font_size": 56,
        "bg_color": (20, 20, 40, 180),  # Dark blue-ish
        "text_color": (255, 255, 255, 255),
        "highlight_color": (0, 255, 255, 255),  # Cyan highlight
        "radius": 20,
        "padding": 45,
        "has_glow": True,
        "glow_color": (0, 255, 255, 200),
        "stroke_width": 0,
    },
    "bold": {
        "name": "Bold Pop",
        "font_size": 60,
        "bg_color": (0, 0, 0, 0),  # No background
        "text_color": (255, 255, 255, 255),
        "highlight_color": (255, 50, 50, 255),  # Red highlight
        "radius": 0,
        "padding": 50,
        "has_glow": False,
        "stroke_width": 4,
        "stroke_color": (0, 0, 0, 255),
    },
    "minimal": {
        "name": "Minimal Clean",
        "font_size": 48,
        "bg_color": (255, 255, 255, 200),  # White background
        "text_color": (0, 0, 0, 255),  # Black text
        "highlight_color": (255, 100, 0, 255),  # Orange highlight
        "radius": 12,
        "padding": 35,
        "has_glow": False,
        "stroke_width": 0,
    },
    "gradient": {
        "name": "Gradient Style",
        "font_size": 54,
        "bg_color": (80, 0, 120, 160),  # Purple gradient-ish
        "text_color": (255, 255, 255, 255),
        "highlight_color": (255, 200, 0, 255),  # Gold highlight
        "radius": 18,
        "padding": 42,
        "has_glow": True,
        "glow_color": (255, 200, 0, 150),
        "stroke_width": 0,
    }
}

def create_caption_images_with_template(captions, output_dir, template="classic"):
    """Create caption images using specified template"""
    style = TEMPLATES.get(template, TEMPLATES["classic"])
    overlay_data = []
    
    # Load font
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", style["font_size"])
    except:
        try:
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", style["font_size"])
        except:
            font = ImageFont.load_default()
    
    # Process each caption segment
    for seg_idx, caption in enumerate(captions):
        words = caption.get('words', [])
        if not words:
            continue
        
        full_text = ' '.join([w['word'] for w in words])
        
        # Create highlighted versions for each word
        for word_idx, word_data in enumerate(words):
            img_path = create_styled_text_image(
                full_text, font, output_dir, 
                f"seg_{seg_idx}_w_{word_idx}",
                highlight_idx=word_idx,
                words_list=words,
                style=style
            )
            
            overlay_data.append({
                'path': img_path,
                'start': word_data['start'],
                'end': word_data['end'],
            })
    
    return overlay_data

def create_styled_text_image(text, font, output_dir, name, highlight_idx=-1, words_list=None, style=None):
    """Create a caption image with applied template style"""
    if style is None:
        style = TEMPLATES["classic"]
    
    # Measure text
    dummy_img = Image.new('RGBA', (1, 1))
    dummy_draw = ImageDraw.Draw(dummy_img)
    
    # Calculate positions for each word
    words = text.split() if words_list is None else [w['word'] for w in words_list]
    word_positions = []
    x_offset = style["padding"]
    
    for i, word in enumerate(words):
        bbox = dummy_draw.textbbox((0, 0), word + ' ', font=font)
        word_width = bbox[2] - bbox[0]
        word_positions.append((x_offset, word_width, word))
        x_offset += word_width
    
    # Calculate image size
    total_width = x_offset + style["padding"]
    total_height = 130 + (style["padding"] // 2)
    
    # Create image
    img = Image.new('RGBA', (total_width, total_height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw background if needed
    if style["bg_color"][3] > 0:  # If not fully transparent
        if style["radius"] > 0:
            draw.rounded_rectangle(
                [(0, 0), (total_width, total_height)],
                radius=style["radius"],
                fill=style["bg_color"]
            )
        else:
            draw.rectangle(
                [(0, 0), (total_width, total_height)],
                fill=style["bg_color"]
            )
    
    y_pos = 45
    
    # Draw each word
    for i, (x_pos, width, word) in enumerate(word_positions):
        is_highlighted = (i == highlight_idx)
        color = style["highlight_color"] if is_highlighted else style["text_color"]
        
        # Add glow effect for highlighted words if template supports it
        if is_highlighted and style.get("has_glow", False):
            glow_color = style.get("glow_color", style["highlight_color"])
            # Multiple glow layers for intensity
            for offset in [6, 4, 2]:
                draw.text((x_pos + offset, y_pos + offset), word + ' ', font=font, fill=(*glow_color[:3], glow_color[3] // 2))
                draw.text((x_pos - offset, y_pos - offset), word + ' ', font=font, fill=(*glow_color[:3], glow_color[3] // 2))
        
        # Draw text with stroke if needed
        if style["stroke_width"] > 0:
            stroke_color = style.get("stroke_color", (0, 0, 0, 255))
            # Draw stroke
            for adj_x in range(-style["stroke_width"], style["stroke_width"] + 1):
                for adj_y in range(-style["stroke_width"], style["stroke_width"] + 1):
                    if adj_x != 0 or adj_y != 0:
                        draw.text((x_pos + adj_x, y_pos + adj_y), word + ' ', font=font, fill=stroke_color)
        
        # Draw main text
        draw.text((x_pos, y_pos), word + ' ', font=font, fill=color)
    
    # Save
    img_path = Path(output_dir) / f"{name}.png"
    img.save(img_path, 'PNG')
    return str(img_path)

def parse_time_to_seconds(time_str):
    """Convert MM:SS:mmm to seconds"""
    parts = time_str.split(':')
    if len(parts) == 3:
        minutes = int(parts[0])
        seconds = int(parts[1])
        milliseconds = int(parts[2])
        return minutes * 60 + seconds + milliseconds / 1000.0
    return 0.0

def process_video(video_path, captions, aspect_ratio, output_path, job_id, jobs, template="classic"):
    """Process video with captions using specified template"""
    try:
        jobs[job_id]["status"] = "processing"
        jobs[job_id]["progress"] = 10
        
        # Create temp directory
        temp_dir = Path("temp") / job_id
        temp_dir.mkdir(parents=True, exist_ok=True)
        
        # Create caption images with template
        jobs[job_id]["progress"] = 30
        overlay_data = create_caption_images_with_template(captions, temp_dir, template)
        
        # Build FFmpeg command
        jobs[job_id]["progress"] = 50
        
        # Base filter for aspect ratio
        if aspect_ratio == "9:16":
            base_filter = "scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2:color=black"
        else:
            base_filter = "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2:color=black"
        
        # Build filter with all overlays
        filter_complex = f"[0:v]{base_filter}[base];"
        
        current_label = "base"
        overlay_idx = 1
        
        # Add ALL overlays with strict timing
        for i, overlay in enumerate(overlay_data):
            start_time = parse_time_to_seconds(overlay['start'])
            end_time = parse_time_to_seconds(overlay['end'])
            
            next_label = f"v{i}" if i < len(overlay_data) - 1 else "out"
            
            filter_complex += f"[{current_label}][{overlay_idx}:v]overlay=(main_w-overlay_w)/2:main_h-overlay_h-100:enable='between(t,{start_time},{end_time})'[{next_label}];"
            current_label = next_label
            overlay_idx += 1
        
        filter_complex = filter_complex.rstrip(';')
        
        print(f"Processing with template: {TEMPLATES.get(template, TEMPLATES['classic'])['name']}")
        print(f"Created {len(overlay_data)} overlays")
        
        # Build FFmpeg command
        ffmpeg_cmd = ['ffmpeg', '-i', video_path]
        
        for overlay in overlay_data:
            ffmpeg_cmd.extend(['-i', overlay['path']])
        
        ffmpeg_cmd.extend([
            '-filter_complex', filter_complex,
            '-map', '[out]',
            '-map', '0:a?',
            '-c:v', 'libx264',
            '-preset', 'medium',
            '-crf', '23',
            '-pix_fmt', 'yuv420p',
            '-c:a', 'copy',
            '-y', output_path
        ])
        
        # Execute FFmpeg
        jobs[job_id]["progress"] = 70
        result = subprocess.run(ffmpeg_cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"FFmpeg error: {result.stderr[-1000:]}")
            raise Exception(f"FFmpeg failed: {result.stderr[-500:]}")
        
        # Cleanup
        import shutil
        shutil.rmtree(temp_dir)
        os.remove(video_path)
        
        jobs[job_id]["status"] = "completed"
        jobs[job_id]["progress"] = 100
        
    except Exception as e:
        jobs[job_id]["status"] = "failed"
        jobs[job_id]["error"] = str(e)
        print(f"Error processing video: {e}")
        import traceback
        traceback.print_exc()
