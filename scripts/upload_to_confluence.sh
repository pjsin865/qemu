#!/bin/bash
# Upload GitHub Wiki markdown pages to Confluence (Markdown → HTML 직접 변환)
set -euo pipefail

PYTHON=/usr/bin/python3
CONFLUENCE_URL="https://project.coasia.com/confluence"
SPACE_KEY="SpaceDevelopment"
WIKI_SRC="/tmp/qemu.wiki"

# ── 인증 정보 입력 ────────────────────────────────────────
if [ -z "${CONFLUENCE_USER:-}" ] || [ -z "${CONFLUENCE_PASS:-}" ]; then
    read -rp "Confluence ID: " CONFLUENCE_USER
    read -rsp "Confluence PW: " CONFLUENCE_PASS
    echo
fi

if [ -z "$CONFLUENCE_USER" ] || [ -z "$CONFLUENCE_PASS" ]; then
    echo "ERROR: ID 또는 PW가 비어 있습니다." >&2; exit 1
fi

# ── 상위 페이지 URL → pageId 추출 ────────────────────────
read -rp "상위 페이지 URL: " PAGE_URL
PARENT_PAGE_ID=$($PYTHON -c "
import sys
from urllib.parse import urlparse, parse_qs
qs = parse_qs(urlparse(sys.argv[1]).query)
print(qs.get('pageId', [''])[0])
" "$PAGE_URL" 2>/dev/null)

if [ -z "$PARENT_PAGE_ID" ]; then
    echo "ERROR: URL에서 pageId를 찾을 수 없습니다." >&2; exit 1
fi

AUTH="$CONFLUENCE_USER:$CONFLUENCE_PASS"

# ── 인증 및 상위 페이지 검증 ─────────────────────────────
echo -n "==> 인증 및 페이지 확인 중... "
RESPONSE=$(curl -s -w "\n%{http_code}" -u "$AUTH" \
    "$CONFLUENCE_URL/rest/api/content/$PARENT_PAGE_ID?expand=space")
HTTP_STATUS=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

case "$HTTP_STATUS" in
    200)
        PAGE_TITLE=$(echo "$BODY" | $PYTHON -c \
            "import sys,json; print(json.load(sys.stdin).get('title',''))")
        echo "OK"
        echo "    페이지: \"$PAGE_TITLE\" (ID: $PARENT_PAGE_ID)"
        ;;
    401) echo "FAILED"; echo "ERROR: ID/PW 오류 (HTTP 401)" >&2; exit 1 ;;
    403) echo "FAILED"; echo "ERROR: 접근 권한 없음 (HTTP 403)" >&2; exit 1 ;;
    404) echo "FAILED"; echo "ERROR: 페이지 없음 (HTTP 404)" >&2; exit 1 ;;
    *)   echo "FAILED"; echo "ERROR: HTTP $HTTP_STATUS" >&2; exit 1 ;;
esac

# ── Markdown → HTML 변환 + 링크 치환 Python 스크립트 ────
CONVERTER=$($PYTHON -c "import tempfile,os; f=tempfile.NamedTemporaryFile(suffix='.py',delete=False); print(f.name)")
cat > "$CONVERTER" << 'PYEOF'
import sys, json, re
import markdown

confluence_url = sys.argv[1]
space_key      = sys.argv[2]
parent_id      = sys.argv[3]
md_file        = sys.argv[4]
mode           = sys.argv[5]          # "create" or "update"
existing_id    = sys.argv[6] if len(sys.argv) > 6 else ""
next_version   = int(sys.argv[7]) if len(sys.argv) > 7 else 1

# 위키 페이지명 → Confluence 제목 매핑
LINK_MAP = {
    "Home":                "QEMU - Home",
    "Getting-Started":     "QEMU - Getting Started",
    "Build-Guide":         "QEMU - Build Guide",
    "Running-Targets":     "QEMU - Running Targets",
    "CLI-Reference":       "QEMU - CLI Reference",
    "Architecture":        "QEMU - Architecture",
    "Troubleshooting":     "QEMU - Troubleshooting",
    "Release-Notes":       "QEMU - Release Notes",
    "Development-Log":     "QEMU - Development Log",
    "Home-en":             "QEMU - Home (English)",
    "Getting-Started-en":  "QEMU - Getting Started (English)",
    "Build-Guide-en":      "QEMU - Build Guide (English)",
    "Running-Targets-en":  "QEMU - Running Targets (English)",
    "CLI-Reference-en":    "QEMU - CLI Reference (English)",
    "Architecture-en":     "QEMU - Architecture (English)",
    "Troubleshooting-en":  "QEMU - Troubleshooting (English)",
    "Release-Notes-en":    "QEMU - Release Notes (English)",
}

content = open(md_file, encoding="utf-8").read()

# 마크다운 상대 링크를 Confluence URL로 치환 (변환 전)
def md_link_replace(m):
    text, target = m.group(1), m.group(2)
    if target in LINK_MAP:
        url_title = LINK_MAP[target].replace(" ", "+")
        return "[{}]({}/display/{}/{})".format(text, confluence_url, space_key, url_title)
    return m.group(0)
content = re.sub(r"\[([^\]]+)\]\(([A-Za-z0-9_-]+)\)", md_link_replace, content)

# Markdown → HTML 변환
html = markdown.markdown(
    content,
    extensions=["tables", "fenced_code", "nl2br", "sane_lists"]
)

# HTML anchor 링크도 치환
def html_link_replace(m):
    href, text = m.group(1), m.group(2)
    if href in LINK_MAP:
        url_title = LINK_MAP[href].replace(" ", "+")
        new_href = "{}/display/{}/{}".format(confluence_url, space_key, url_title)
        return '<a href="{}">{}</a>'.format(new_href, text)
    return m.group(0)
html = re.sub(r'<a href="([^"]+)">([^<]*)</a>', html_link_replace, html)

data = {
    "type": "page",
    "title": open(md_file).readline().lstrip("# ").strip(),  # 제목은 첫 번째 헤더
    "space": {"key": space_key},
    "ancestors": [{"id": int(parent_id)}],
    "body": {"storage": {"value": html, "representation": "storage"}}
}

if mode == "update":
    data["id"] = existing_id
    data["version"] = {"number": next_version}

print(json.dumps(data))
PYEOF

# ── 페이지 업로드 함수 ────────────────────────────────────
upload_page() {
    local title="$1"
    local md_file="$2"
    local tmp_payload
    tmp_payload=$(mktemp /tmp/confluence_XXXXXX.json)
    trap "rm -f $tmp_payload" RETURN

    # 기존 페이지 여부 확인
    local encoded_title
    encoded_title=$($PYTHON -c \
        "import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1]))" "$title")
    local existing_id
    existing_id=$(curl -s -u "$AUTH" \
        "$CONFLUENCE_URL/rest/api/content?title=${encoded_title}&spaceKey=$SPACE_KEY&expand=version" \
        | $PYTHON -c \
        "import sys,json; d=json.load(sys.stdin); print(d['results'][0]['id'] if d['results'] else '')" \
        2>/dev/null)

    if [ -n "$existing_id" ]; then
        local version next_version
        version=$(curl -s -u "$AUTH" \
            "$CONFLUENCE_URL/rest/api/content/$existing_id?expand=version" \
            | $PYTHON -c "import sys,json; print(json.load(sys.stdin)['version']['number'])")
        next_version=$(( version + 1 ))

        $PYTHON "$CONVERTER" \
            "$CONFLUENCE_URL" "$SPACE_KEY" "$PARENT_PAGE_ID" "$md_file" \
            "update" "$existing_id" "$next_version" > "$tmp_payload"

        result=$(curl -s -u "$AUTH" \
            -X PUT -H "Content-Type: application/json" \
            "$CONFLUENCE_URL/rest/api/content/$existing_id" \
            --data @"$tmp_payload")
        echo "  [UPDATE] $title → $(echo "$result" | $PYTHON -c \
            "import sys,json; d=json.load(sys.stdin); print(d.get('_links',{}).get('webui','error'))" 2>/dev/null)"
    else
        $PYTHON "$CONVERTER" \
            "$CONFLUENCE_URL" "$SPACE_KEY" "$PARENT_PAGE_ID" "$md_file" \
            "create" > "$tmp_payload"

        # payload의 title을 인수로 받은 title로 덮어쓰기
        $PYTHON -c "
import sys, json
d = json.load(open(sys.argv[1]))
d['title'] = sys.argv[2]
print(json.dumps(d))
" "$tmp_payload" "$title" > "${tmp_payload}.fixed" && mv "${tmp_payload}.fixed" "$tmp_payload"

        result=$(curl -s -u "$AUTH" \
            -X POST -H "Content-Type: application/json" \
            "$CONFLUENCE_URL/rest/api/content" \
            --data @"$tmp_payload")
        echo "  [CREATE] $title → $(echo "$result" | $PYTHON -c \
            "import sys,json; d=json.load(sys.stdin); print(d.get('_links',{}).get('webui','error'))" 2>/dev/null)"
    fi
}

# ── 업로드 실행 ───────────────────────────────────────────
echo ""
echo "==> Uploading wiki pages to Confluence (Space: $SPACE_KEY)"
echo "    Parent page ID: $PARENT_PAGE_ID"
echo ""

upload_page "QEMU - Home"             "$WIKI_SRC/Home.md"
upload_page "QEMU - Getting Started"  "$WIKI_SRC/Getting-Started.md"
upload_page "QEMU - Build Guide"      "$WIKI_SRC/Build-Guide.md"
upload_page "QEMU - Running Targets"  "$WIKI_SRC/Running-Targets.md"
upload_page "QEMU - CLI Reference"    "$WIKI_SRC/CLI-Reference.md"
upload_page "QEMU - Architecture"     "$WIKI_SRC/Architecture.md"
upload_page "QEMU - Troubleshooting"  "$WIKI_SRC/Troubleshooting.md"
upload_page "QEMU - Release Notes"    "$WIKI_SRC/Release-Notes.md"
upload_page "QEMU - Development Log"  "$WIKI_SRC/Development-Log.md"

rm -f "$CONVERTER"
echo ""
echo "==> Done. Confluence: $CONFLUENCE_URL/display/$SPACE_KEY"
