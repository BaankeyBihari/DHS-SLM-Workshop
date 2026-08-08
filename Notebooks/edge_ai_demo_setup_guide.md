# Edge AI Demo — Setup Guide (Windows)

Run a small language model fully offline on a laptop, then let a room full of phones talk to it over the local Wi-Fi. No cloud, no API key, no data leaving the room.

## What you need
- A Windows laptop
- A GGUF model file (this guide uses a small ~135M parameter model, `smollm_135M_q4_k_m.gguf`, so it runs fast on CPU)
- The `medical_demo_v2.html` demo page and everyone's phones on the same Wi-Fi network

---

## 1. Install llama.cpp

```powershell
winget install ggerganov.llama.cpp
```

If `winget` isn't available, download a pre-built zip instead from:
https://github.com/ggerganov/llama.cpp/releases
(pick the Windows CPU build, extract it, and add the folder to your PATH)

Verify it installed:
```powershell
llama-cli --version
```

## 2. Get your GGUF model file in place

Create a folder and drop your `.gguf` file there:
```powershell
mkdir C:\Users\<you>\models
```

If you're not sure where a downloaded file landed, search for it:
```powershell
Get-ChildItem -Path C:\Users\<you> -Recurse -Filter *.gguf -ErrorAction SilentlyContinue | Select-Object FullName, Length
```

Then move it into place:
```powershell
move C:\Users\<you>\Downloads\<your-model>.gguf C:\Users\<you>\models\
```

## 3. Quick sanity test (optional but recommended)

```powershell
llama-cli --model "C:\Users\<you>\models\<your-model>.gguf" --prompt "Translate to French: Good morning." --n-predict 50 --threads 4 --no-display-prompt
```

**Important:** running `llama-cli` without `--n-predict` set low, or interrupting it wrong, can drop you into an interactive chat loop. Type `/exit` or press `Ctrl+C` to leave it before moving to the next step — don't paste the server command into a `llama-cli` session, it'll misread it as chat input.

## 4. Launch the local API server

Use a single line (avoids PowerShell issues with backtick line-continuation):

```powershell
llama-server --model "C:\Users\<you>\models\<your-model>.gguf" --host 0.0.0.0 --port 8080 --threads 6 --ctx-size 2048 --n-predict 80
```

- `--host 0.0.0.0` is critical — it's what makes the server reachable from other devices on the network, not just the laptop itself.
- Adjust `--threads` to roughly match your CPU's core count.
- Leave off `--log-disable` the first time so you can actually see it boot. Wait for:
  ```
  HTTP server listening on 0.0.0.0:8080
  ```
- **Keep this terminal window open** for the rest of the demo — closing it kills the server.
- If Windows Firewall prompts you, click **Allow**.

### Verify it's alive (in a second terminal window)
```powershell
curl.exe -s http://localhost:8080/health
```
Expect: `{"status":"ok"}`

### Verify it actually answers
```powershell
@"
{
  "model": "smollm",
  "messages": [
    {"role": "system", "content": "You are a concise assistant. Answer in 1-2 sentences only."},
    {"role": "user", "content": "What is the normal human body temperature?"}
  ],
  "max_tokens": 80,
  "temperature": 0.1
}
"@ | Out-File -FilePath "C:\Users\<you>\request.json" -Encoding utf8

curl.exe -s http://localhost:8080/v1/chat/completions -H "Content-Type: application/json" -d "@C:\Users\<you>\request.json"
```
You should get back a JSON response with a `content` field and `timings` showing tokens/second.

## 5. Find your laptop's local IP

```powershell
ipconfig | findstr IPv4
```

Note the address — e.g. `192.168.1.6`. Everyone's phone will connect to this.

## 6. Update the demo HTML file with your IP

Open `medical_demo_v2.html` in a text editor and replace the placeholder IP in **two places** with your real one:
- The `SERVER` constant near the top of the `<script>` block
- The IP shown in the footer text

## 7. Serve the demo page

In a **third** terminal window, from the folder containing the HTML file:
```powershell
cd C:\Users\<you>
python -m http.server 3000
```

## 8. Connect from a phone

1. Join the **same Wi-Fi network** as the laptop (not mobile data).
2. Open a browser and go to:
   ```
   http://<your-laptop-ip>:3000/medical_demo_v2.html
   ```

Optional: generate a QR code encoding that URL so people can scan instead of typing.

---

## Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| `llama-cli` seems to be answering nonsense to pasted commands | It's stuck in interactive chat mode. `Ctrl+C` or close the window, open a fresh one. |
| PowerShell shows `>>` and won't run the command | A trailing space snuck in after a line-continuation backtick. Retype as one single line instead. |
| No `HTTP server listening` message appears | If you used `--log-disable`, that's expected — it suppresses this message too. Test with `curl.exe -s http://localhost:8080/health` instead. |
| Browser/phone gets a 404 | The HTML file isn't in the folder you're serving from (`python -m http.server` serves the current directory). Check with `Get-ChildItem` and move the file if needed. |
| Phone can't reach the laptop at all | Confirm both are on the same Wi-Fi; check Windows Firewall didn't block Python or `llama-server`; some "Guest" networks isolate devices from each other — try a personal hotspot instead if so. |

## Notes for whoever's presenting
- Three terminal windows need to stay open simultaneously: `llama-server`, `python -m http.server`, and a free one for testing/troubleshooting.
- This is a small model chosen for speed and offline demo purposes — it's good for showing edge inference is possible, not for factual reliability. Worth saying so out loud if the demo touches any factual/medical topic.
