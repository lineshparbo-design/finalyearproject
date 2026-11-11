"""Development-only AI proxy. Bind locally; put authenticated HTTPS in front for deployment."""
import json
import os
import urllib.request
import urllib.error
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

class Handler(BaseHTTPRequestHandler):
    def headers_out(self, status):
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', os.environ.get('ALLOWED_ORIGIN', 'http://localhost:8080'))
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.end_headers()

    def do_OPTIONS(self):
        self.headers_out(204)

    def do_POST(self):
        if self.path != '/chat':
            self.headers_out(404)
            return
        key = os.environ.get('OPENAI_API_KEY')
        if not key:
            self.headers_out(503)
            self.wfile.write(b'{"error":"AI provider is not configured"}')
            return
        try:
            length = int(self.headers.get('Content-Length', '0'))
            if not 0 < length <= 32768:
                raise ValueError('Invalid body size')
            data = json.loads(self.rfile.read(length))
            history = data.get('messages', [])[-16:]
            if not isinstance(history, list):
                raise ValueError('Invalid messages')
            messages = [{'role':'system','content':
                'You are MauriGuide, a Mauritius tourism assistant. Answer in the requested language: '
                + str(data.get('language', 'English'))[:30]
                + '. Interests: ' + str(data.get('interests', []))[:200]
                + '. Daily activity budget in MUR: ' + str(data.get('budget', 'unknown'))[:20]
                + '. Be concise, culturally respectful, and encourage sustainable travel. '
                'You have no live tools or verified current weather, events, prices, hours, or availability. '
                'Say so when asked and suggest checking official operators. Never invent bookings or live facts.'}]
            for m in history:
                if m.get('role') not in ('user','assistant') or not isinstance(m.get('text'),str):
                    raise ValueError('Invalid message')
                messages.append({'role':m['role'],'content':m['text'][:4000]})
            payload = json.dumps({'model':os.environ.get('OPENAI_MODEL','gpt-4.1-mini'),
                                  'messages':messages,'max_tokens':700}).encode()
            request = urllib.request.Request('https://api.openai.com/v1/chat/completions', data=payload,
                       headers={'Content-Type':'application/json','Authorization':'Bearer '+key})
            with urllib.request.urlopen(request, timeout=20) as response:
                result = json.load(response)
            self.headers_out(200)
            self.wfile.write(json.dumps({'reply':result['choices'][0]['message']['content']}).encode())
        except (ValueError, KeyError, TypeError):
            self.headers_out(400)
            self.wfile.write(b'{"error":"Invalid request"}')
        except (urllib.error.URLError, TimeoutError):
            self.headers_out(502)
            self.wfile.write(b'{"error":"AI provider unavailable"}')

if __name__ == '__main__':
    ThreadingHTTPServer(('127.0.0.1', 8787), Handler).serve_forever()
