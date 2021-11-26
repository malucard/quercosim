export COMMIT_TITLE=$(git log --format="%s" -n 1 | jq -aRs .)
export COMMIT_DESC=$(git log --format="%b" -n 1 | jq -aRs .)
export COMMIT_AUTHOR=$(git log --format="%an" -n 1)
export COMMIT_AURL="https://github.com/$(git log --format="%an" -n 1)"
export COMMIT_URL="https://github.com/malucard/quercosim/commit/$(git log --format="%h" -n 1)"
if [[ $(git log -1 --oneline) == *"[RELEASE]"* ]]; then
    export COMMIT_DESC=${COMMIT_DESC::-1}"get [on itch.io](https://malucart.itch.io/qads), or update on the itch client\""
    #export FOOTER=', "footer": {"text": "get [on itch.io](https://malucart.itch.io/aai0-qads), or update on the itch client", "url": "https://malucart.itch.io/qads", "icon_url": "https://media.discordapp.net/attachments/743938593403437168/913899315192283156/itchio-textless-white.png"}'
else
    export FOOTER=''
fi
export FOOTER=''
curl -H "Content-Type: application/json" \
	-d '{"embeds": [{"title": '"$COMMIT_TITLE"', "url": "'"$COMMIT_URL"'", "description": '"$COMMIT_DESC"', "author": {"name": "'"$COMMIT_AUTHOR"'", "url": "'"$COMMIT_AURL"'", "icon_url": "'"$COMMIT_AURL.png"'"}'"$FOOTER"'}]}' "$WEBHOOK_URL"
