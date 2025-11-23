import requests
import json
import time
from pathlib import Path

# Server URL
SERVER_URL = "http://localhost:8000"

# Sample video path
video_path = "../videos/VN20251120_185610.mp4"

# Real captions from user's app (Hinglish)
sample_captions = [{"text":"So guys, aaj","start":"00:00:266","end":"00:01:836","words":[{"word":"So","start":"00:00:266","end":"00:00:466"},{"word":"guys,","start":"00:00:466","end":"00:01:056"},{"word":"aaj","start":"00:01:466","end":"00:01:836"}]},{"text":"main ek nayi cheez","start":"00:01:836","end":"00:03:006","words":[{"word":"main","start":"00:01:836","end":"00:02:136"},{"word":"ek","start":"00:02:136","end":"00:02:306"},{"word":"nayi","start":"00:02:306","end":"00:02:646"},{"word":"cheez","start":"00:02:646","end":"00:03:006"}]},{"text":"lekar ke aa gayi","start":"00:03:006","end":"00:04:156","words":[{"word":"lekar","start":"00:03:006","end":"00:03:416"},{"word":"ke","start":"00:03:416","end":"00:03:576"},{"word":"aa","start":"00:03:576","end":"00:03:776"},{"word":"gayi","start":"00:03:776","end":"00:04:156"}]},{"text":"hoon jo hai Parisar","start":"00:04:156","end":"00:05:466","words":[{"word":"hoon","start":"00:04:156","end":"00:04:366"},{"word":"jo","start":"00:04:606","end":"00:04:846"},{"word":"hai","start":"00:04:846","end":"00:05:076"},{"word":"Parisar","start":"00:05:076","end":"00:05:466"}]},{"text":"Apple Cider Vinegar","start":"00:05:466","end":"00:07:376","words":[{"word":"Apple","start":"00:05:506","end":"00:05:756"},{"word":"Cider","start":"00:05:756","end":"00:06:506"},{"word":"Vinegar","start":"00:06:506","end":"00:07:376"}]},{"text":"ki tablets and trust","start":"00:07:376","end":"00:08:426","words":[{"word":"ki","start":"00:07:376","end":"00:07:446"},{"word":"tablets","start":"00:07:446","end":"00:07:956"},{"word":"and","start":"00:07:956","end":"00:08:146"},{"word":"trust","start":"00:08:146","end":"00:08:426"}]},{"text":"me this one is","start":"00:08:426","end":"00:09:076","words":[{"word":"me","start":"00:08:426","end":"00:08:586"},{"word":"this","start":"00:08:586","end":"00:08:816"},{"word":"one","start":"00:08:816","end":"00:08:926"},{"word":"is","start":"00:08:926","end":"00:09:076"}]},{"text":"a game changer.","start":"00:09:076","end":"00:10:046","words":[{"word":"a","start":"00:09:076","end":"00:09:156"},{"word":"game","start":"00:09:156","end":"00:09:416"},{"word":"changer.","start":"00:09:416","end":"00:10:046"}]},{"text":"Bas ek tablet lo,","start":"00:10:046","end":"00:10:876","words":[{"word":"Bas","start":"00:10:046","end":"00:10:296"},{"word":"ek","start":"00:10:296","end":"00:10:446"},{"word":"tablet","start":"00:10:446","end":"00:10:766"},{"word":"lo,","start":"00:10:766","end":"00:10:876"}]},{"text":"pani mein daalo","start":"00:10:876","end":"00:12:056","words":[{"word":"pani","start":"00:10:976","end":"00:11:276"},{"word":"mein","start":"00:11:276","end":"00:11:476"},{"word":"daalo","start":"00:11:476","end":"00:12:056"}]},{"text":"aur dekho refreshing","start":"00:12:056","end":"00:13:216","words":[{"word":"aur","start":"00:12:056","end":"00:12:216"},{"word":"dekho","start":"00:12:216","end":"00:12:806"},{"word":"refreshing","start":"00:12:806","end":"00:13:216"}]},{"text":"drink ready in seconds.","start":"00:13:216","end":"00:14:626","words":[{"word":"drink","start":"00:13:216","end":"00:13:586"},{"word":"ready","start":"00:13:586","end":"00:14:046"},{"word":"in","start":"00:14:046","end":"00:14:146"},{"word":"seconds.","start":"00:14:146","end":"00:14:626"}]},{"text":"Ye na sirf tasty","start":"00:14:736","end":"00:15:676","words":[{"word":"Ye","start":"00:14:736","end":"00:14:876"},{"word":"na","start":"00:14:876","end":"00:15:066"},{"word":"sirf","start":"00:15:066","end":"00:15:356"},{"word":"tasty","start":"00:15:356","end":"00:15:676"}]},{"text":"mein accha hai,","start":"00:15:676","end":"00:16:326","words":[{"word":"mein","start":"00:15:676","end":"00:15:936"},{"word":"accha","start":"00:15:936","end":"00:16:166"},{"word":"hai,","start":"00:16:166","end":"00:16:326"}]},{"text":"balki full of nutrients","start":"00:16:326","end":"00:17:856","words":[{"word":"balki","start":"00:16:326","end":"00:16:796"},{"word":"full","start":"00:16:796","end":"00:17:096"},{"word":"of","start":"00:17:096","end":"00:17:286"},{"word":"nutrients","start":"00:17:286","end":"00:17:856"}]},{"text":"bhi hai aur","start":"00:17:856","end":"00:18:766","words":[{"word":"bhi","start":"00:17:856","end":"00:18:246"},{"word":"hai","start":"00:18:246","end":"00:18:616"},{"word":"aur","start":"00:18:616","end":"00:18:766"}]},{"text":"agar aap isko","start":"00:18:766","end":"00:19:646","words":[{"word":"agar","start":"00:18:766","end":"00:18:966"},{"word":"aap","start":"00:18:966","end":"00:19:156"},{"word":"isko","start":"00:19:156","end":"00:19:646"}]},{"text":"daily basis pe","start":"00:19:756","end":"00:20:706","words":[{"word":"daily","start":"00:19:756","end":"00:20:076"},{"word":"basis","start":"00:20:076","end":"00:20:496"},{"word":"pe","start":"00:20:496","end":"00:20:706"}]},{"text":"apna use kar","start":"00:20:706","end":"00:21:566","words":[{"word":"apna","start":"00:20:706","end":"00:20:986"},{"word":"use","start":"00:20:986","end":"00:21:356"},{"word":"kar","start":"00:21:356","end":"00:21:566"}]},{"text":"rahe ho, daily","start":"00:21:566","end":"00:22:316","words":[{"word":"rahe","start":"00:21:566","end":"00:21:776"},{"word":"ho,","start":"00:21:776","end":"00:22:046"},{"word":"daily","start":"00:22:046","end":"00:22:316"}]},{"text":"pee rahe ho,","start":"00:22:316","end":"00:23:076","words":[{"word":"pee","start":"00:22:316","end":"00:22:526"},{"word":"rahe","start":"00:22:526","end":"00:22:786"},{"word":"ho,","start":"00:22:786","end":"00:23:076"}]},{"text":"toh aapko digestion","start":"00:23:076","end":"00:24:256","words":[{"word":"toh","start":"00:23:076","end":"00:23:256"},{"word":"aapko","start":"00:23:256","end":"00:23:516"},{"word":"digestion","start":"00:23:516","end":"00:24:256"}]},{"text":"mein better karega,","start":"00:24:256","end":"00:25:216","words":[{"word":"mein","start":"00:24:256","end":"00:24:436"},{"word":"better","start":"00:24:436","end":"00:24:876"},{"word":"karega,","start":"00:24:876","end":"00:25:216"}]},{"text":"theek hai, aur","start":"00:25:216","end":"00:25:956","words":[{"word":"theek","start":"00:25:216","end":"00:25:526"},{"word":"hai,","start":"00:25:526","end":"00:25:706"},{"word":"aur","start":"00:25:706","end":"00:25:956"}]},{"text":"energy bhi badhayega","start":"00:25:956","end":"00:26:686","words":[{"word":"energy","start":"00:25:956","end":"00:26:266"},{"word":"bhi","start":"00:26:266","end":"00:26:476"},{"word":"badhayega","start":"00:26:476","end":"00:26:686"}]},{"text":"apki. And","start":"00:26:686","end":"00:27:856","words":[{"word":"apki.","start":"00:26:686","end":"00:27:076"},{"word":"And","start":"00:27:076","end":"00:27:856"}]},{"text":"weight management mein","start":"00:27:856","end":"00:29:416","words":[{"word":"weight","start":"00:27:856","end":"00:28:446"},{"word":"management","start":"00:28:446","end":"00:29:136"},{"word":"mein","start":"00:29:136","end":"00:29:416"}]},{"text":"bhi help karega","start":"00:29:416","end":"00:30:576","words":[{"word":"bhi","start":"00:29:416","end":"00:29:656"},{"word":"help","start":"00:29:656","end":"00:29:946"},{"word":"karega","start":"00:29:946","end":"00:30:576"}]},{"text":"aur bas try","start":"00:31:026","end":"00:32:026","words":[{"word":"aur","start":"00:31:026","end":"00:31:636"},{"word":"bas","start":"00:31:636","end":"00:31:856"},{"word":"try","start":"00:31:856","end":"00:32:026"}]},{"text":"karo guys. Bahut","start":"00:32:026","end":"00:33:146","words":[{"word":"karo","start":"00:32:026","end":"00:32:416"},{"word":"guys.","start":"00:32:416","end":"00:32:826"},{"word":"Bahut","start":"00:32:826","end":"00:33:146"}]},{"text":"accha hai. Main","start":"00:33:146","end":"00:34:256","words":[{"word":"accha","start":"00:33:146","end":"00:33:436"},{"word":"hai.","start":"00:33:436","end":"00:33:576"},{"word":"Main","start":"00:33:966","end":"00:34:256"}]},{"text":"isko do hafte","start":"00:34:256","end":"00:35:056","words":[{"word":"isko","start":"00:34:256","end":"00:34:496"},{"word":"do","start":"00:34:496","end":"00:34:646"},{"word":"hafte","start":"00:34:646","end":"00:35:056"}]},{"text":"se pee rahi hoon.","start":"00:35:056","end":"00:35:866","words":[{"word":"se","start":"00:35:056","end":"00:35:216"},{"word":"pee","start":"00:35:216","end":"00:35:466"},{"word":"rahi","start":"00:35:466","end":"00:35:666"},{"word":"hoon.","start":"00:35:666","end":"00:35:866"}]}]

def test_server():
    print("🧪 Testing server with sample video...\n")
    
    # Check if video exists
    if not Path(video_path).exists():
        print(f"❌ Video not found: {video_path}")
        print("Please update the video_path variable in this script")
        return
    
    # Get available templates
    response = requests.get(f"{SERVER_URL}/templates")
    templates = response.json()["templates"]
    print(f"📋 Available templates: {', '.join([t['name'] for t in templates])}\n")
    
    # Test with "neon" template (or change to any template)
    template = "classic"  # Options: classic, neon, bold, minimal, gradient
    print(f"🎨 Using template: {template}\n")
    
    # 1. Upload video
    print("📤 Uploading video and captions...")
    with open(video_path, 'rb') as video_file:
        files = {'video': video_file}
        data = {
            'captions': json.dumps(sample_captions),
            'aspect_ratio': '9:16',
            'template': template  # Specify template
        }
        
        response = requests.post(f"{SERVER_URL}/upload", files=files, data=data)
        
        if response.status_code != 200:
            print(f"❌ Upload failed: {response.text}")
            return
        
        result = response.json()
        job_id = result['job_id']
        print(f"✅ Upload successful! Job ID: {job_id}\n")
    
    # 2. Poll for status
    print("⏳ Processing video...")
    while True:
        response = requests.get(f"{SERVER_URL}/status/{job_id}")
        status_data = response.json()
        
        status = status_data.get('status')
        progress = status_data.get('progress', 0)
        
        print(f"   Status: {status} ({progress}%)", end='\r')
        
        if status == 'completed':
            print(f"\n✅ Processing complete!                    \n")
            break
        elif status == 'failed':
            print(f"\n❌ Processing failed: {status_data.get('error')}\n")
            return
        
        time.sleep(1)
    
    # 3. Download result
    print("⬇️  Downloading processed video...")
    response = requests.get(f"{SERVER_URL}/download/{job_id}")
    
    if response.status_code == 200:
        output_path = "test_output.mp4"
        with open(output_path, 'wb') as f:
            f.write(response.content)
        print(f"✅ Video saved to: {output_path}")
        print(f"\n🎉 SUCCESS! Open {output_path} to see the result with word highlighting!")
    else:
        print(f"❌ Download failed: {response.text}")

if __name__ == "__main__":
    test_server()
