#!/bin/bash
API_KEY="FPSXd04ecc50758e2543ff8a5e6ca2ac8010"
BASE="https://api.freepik.com"

poll_and_download() {
  local ENDPOINT="$1"
  local TASK_ID="$2"
  local OUTPUT="$3"
  local MAX_WAIT=120
  local ELAPSED=0
  
  while [ $ELAPSED -lt $MAX_WAIT ]; do
    RESP=$(curl -s -X GET "$BASE$ENDPOINT/$TASK_ID" \
      -H "x-freepik-api-key: $API_KEY")
    STATUS=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('status','UNKNOWN'))" 2>/dev/null)
    
    if [ "$STATUS" = "COMPLETED" ]; then
      IMG_URL=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); imgs=d.get('data',{}).get('generated',[]); print(imgs[0] if imgs else '')" 2>/dev/null)
      if [ -n "$IMG_URL" ]; then
        curl -s -o "$OUTPUT" "$IMG_URL"
        echo "Downloaded: $OUTPUT"
        return 0
      fi
    elif [ "$STATUS" = "FAILED" ]; then
      echo "FAILED: $OUTPUT"
      echo "$RESP" | python3 -m json.tool 2>/dev/null || echo "$RESP"
      return 1
    fi
    
    sleep 3
    ELAPSED=$((ELAPSED + 3))
  done
  echo "TIMEOUT: $OUTPUT"
  return 1
}

generate_mystic() {
  local PROMPT="$1"
  local OUTPUT="$2"
  
  RESP=$(curl -s -X POST "$BASE/v1/ai/mystic" \
    -H "x-freepik-api-key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"prompt\": \"$PROMPT\",
      \"resolution\": \"2k\",
      \"aspect_ratio\": \"square_1_1\",
      \"model\": \"realism\",
      \"styling\": {
        \"colors\": [
          {\"color\": \"#8b5cf6\", \"weight\": 0.12}
        ]
      },
      \"creative_detailing\": 60,
      \"hdr\": 55
    }")
  
  TASK_ID=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('task_id',''))" 2>/dev/null)
  
  if [ -n "$TASK_ID" ] && [ "$TASK_ID" != "" ]; then
    echo "Task $TASK_ID for $OUTPUT"
    poll_and_download "/v1/ai/mystic" "$TASK_ID" "$OUTPUT"
  else
    echo "Failed to create task for $OUTPUT"
    echo "$RESP"
    return 1
  fi
}

echo "=== Generating MarkoChat Homepage Assets ==="

# Testimonial avatars
echo "--- Avatar 1: James R. ---"
generate_mystic "professional headshot portrait of a confident man in his early 40s, short brown hair, warm smile, wearing a dark navy blue blazer over a light gray shirt, natural soft lighting, clean neutral background with very subtle warm tones, corporate professional photography, sharp focus on face, shallow depth of field" "images/avatars/james.jpg" &

echo "--- Avatar 2: Maria K. ---"
generate_mystic "professional headshot portrait of a friendly woman in her mid 30s, dark wavy hair past shoulders, bright genuine smile, wearing a white blouse, natural studio lighting, clean neutral background, corporate photography, high quality portrait, sharp focus, warm and approachable expression" "images/avatars/maria.jpg" &

echo "--- Avatar 3: Tyler B. ---"
generate_mystic "professional headshot portrait of a young entrepreneurial man in his late 20s, light brown hair styled casually, confident relaxed smile, wearing a simple dark crew neck, natural lighting, clean modern background, startup founder vibe, high quality portrait photography, sharp focus" "images/avatars/tyler.jpg" &

# Chat demo - CS agent avatar
echo "--- CS Agent Avatar ---"
generate_mystic "professional headshot of a friendly young woman customer service agent in her late 20s, auburn hair pulled back neatly, wearing a headset with microphone, warm genuine smile, wearing a modern purple business top, clean white background, corporate support team photo, high quality, sharp focus, approachable" "images/avatars/agent-sarah.jpg" &

# Chat demo - customer avatar  
echo "--- Customer Avatar ---"
generate_mystic "casual photo portrait of a woman in her mid 30s, blonde hair, friendly natural expression, wearing a casual light colored top, soft natural lighting, clean background, everyday person look, high quality photography, approachable" "images/avatars/customer.jpg" &

wait
echo "=== All image generation complete ==="
ls -la images/avatars/
