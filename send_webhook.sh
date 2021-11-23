export WEBHOOK_URL="https://canary.discord.com/api/webhooks/912575382564253697/wRykvYMwXvySGQJ-r7o3ORjtIuQ2hkedHkHNjYhiG003dbciIu74z3xHZQTos3v9Dtv5"
export COMMIT_TITLE=$(git log --format="%s" -n 1 | jq -aRs .)
export COMMIT_DESC=$(git log --format="%b" -n 1 | jq -aRs .)
export COMMIT_AUTHOR=$(git log --format="%an" -n 1)
export COMMIT_AURL="https://github.com/$(git log --format="%an" -n 1)"
export COMMIT_URL="https://github.com/malucard/quercosim/commit/$(git log --format="%h" -n 1)"
curl -H "Content-Type: application/json" \
	-d '{"embeds": [{"title": '"$COMMIT_TITLE"', "url": "'"$COMMIT_URL"'", "description": '"$COMMIT_DESC"', "author": {"name": "'"$COMMIT_AUTHOR"'", "url": "'"$COMMIT_AURL"'", "icon_url": "'"$COMMIT_AURL.png"'"}}]}' "$WEBHOOK_URL"
