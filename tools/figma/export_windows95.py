"""Extract Windows 95 components from saved Figma MCP SVG exports.

Requires Python 3 and Microsoft Edge. No Python packages are required.
Run from the repository root. MCP download URLs are supplied at runtime only.
"""

import argparse
import base64
import copy
import hashlib
import html
import json
import math
from pathlib import Path
import re
import struct
import subprocess
import tempfile
import urllib.request
import xml.etree.ElementTree as ET
import zipfile


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "assets/ui/windows95"
TEMP_ROOT = Path(r"C:\Users\Me\AppData\Local\Temp\opencode")
EDGE = Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe")
SVG = "http://www.w3.org/2000/svg"
XLINK = "http://www.w3.org/1999/xlink"
ET.register_namespace("", SVG)
ET.register_namespace("xlink", XLINK)


def browser(document):
    """Execute self-contained local HTML and retrieve its JSON result."""
    with tempfile.TemporaryDirectory(prefix="win95-export-", dir=TEMP_ROOT) as tmp:
        work = Path(tmp)
        page = work / "export.html"
        page.write_text(document, encoding="utf-8")
        completed = subprocess.run(
            [str(EDGE), "--headless", "--disable-gpu", "--no-first-run",
             "--disable-extensions", "--disable-background-networking",
             f"--user-data-dir={work / 'profile'}", "--virtual-time-budget=30000",
             "--dump-dom", page.as_uri()],
            capture_output=True, encoding="utf-8", timeout=120,
        )
        match = re.search(r'<pre id="result">(.*?)</pre>', completed.stdout, re.S)
        if completed.returncode or not match:
            raise RuntimeError(f"Edge export failed: {completed.stderr[-2000:]}")
        result = json.loads(html.unescape(match.group(1)))
        if isinstance(result, dict) and "error" in result:
            raise RuntimeError(result["error"])
        return result


def group_bounds(sources):
    containers = "".join(
        f'<div data-source="{html.escape(key)}">{text}</div>'
        for key, text in sources.items()
    )
    return browser("<!doctype html><meta charset='utf-8'>" + containers + """
<pre id="result"></pre><script>
try {
  const result = {};
  for (const container of document.querySelectorAll('[data-source]')) {
    const groups = [];
    for (const node of container.querySelectorAll('g[id]')) {
      const b = node.getBBox(), m = node.getCTM();
      const corners = [[b.x,b.y],[b.x+b.width,b.y],
                       [b.x,b.y+b.height],[b.x+b.width,b.y+b.height]]
        .map(([x,y])=>new DOMPoint(x,y).matrixTransform(m));
      const x = Math.min(...corners.map(p=>p.x));
      const y = Math.min(...corners.map(p=>p.y));
      groups.push({id:node.id, x, y,
        width:Math.max(...corners.map(p=>p.x))-x,
        height:Math.max(...corners.map(p=>p.y))-y});
    }
    result[container.dataset.source] = groups;
  }
  document.getElementById('result').textContent = JSON.stringify(result);
} catch (e) {
  document.getElementById('result').textContent = JSON.stringify({error:String(e)});
}
</script>""")


def normalized_name(name):
    return re.sub(r"_\d+$", "", name).strip()


def slug(name):
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def references(node):
    text = ET.tostring(node, encoding="unicode")
    return set(re.findall(r"url\(#([^\)]+)\)", text)) | set(
        re.findall(r'(?:href)="\#([^"]+)"', text)
    )


def isolate(tree, group_id, bounds, size):
    """Keep only selected group, ancestor transforms, and referenced definitions."""
    index = {node.attrib["id"]: node for node in tree.iter() if "id" in node.attrib}
    parents = {child: parent for parent in tree.iter() for child in parent}
    target = index[group_id]
    branch = copy.deepcopy(target)
    parent = parents.get(target)
    while parent is not None and parent is not tree:
        wrapper = ET.Element(parent.tag, dict(parent.attrib))
        wrapper.append(branch)
        branch = wrapper
        parent = parents.get(parent)
    width, height = size
    root = ET.Element(f"{{{SVG}}}svg", {
        "width": f"{width:.12g}", "height": f"{height:.12g}",
        "viewBox": " ".join(f"{v:.12g}" for v in bounds),
        "fill": "none",
    })
    root.append(branch)
    pending = references(branch)
    added = set()
    defs = ET.Element(f"{{{SVG}}}defs")
    while pending:
        name = min(pending)
        pending.remove(name)
        if name in added:
            continue
        if name not in index:
            raise ValueError(f"Missing SVG reference: {name}")
        dependency = index[name]
        defs.append(copy.deepcopy(dependency))
        added.add(name)
        pending.update(references(dependency) - added)
    if len(defs):
        root.append(defs)
    return ET.tostring(root, encoding="unicode")


def select_group(groups, name, expected, tolerance=3):
    candidates = [g for g in groups if normalized_name(g["id"]) == name.strip()]
    if not candidates:
        raise ValueError(f"No SVG group named {name!r}")
    x, y, width, height = expected
    def distance(g):
        # Transparent components can have layout padding absent from getBBox().
        return max(abs(g["x"] + g["width"] / 2 - x - width / 2),
                   abs(g["y"] + g["height"] / 2 - y - height / 2),
                   max(0, x - g["x"], y - g["y"],
                       g["x"] + g["width"] - x - width,
                       g["y"] + g["height"] - y - height))
    selected = min(candidates, key=distance)
    if distance(selected) > tolerance:
        raise ValueError(f"Uncertain match for {name!r}: expected {expected}, got {selected}")
    return selected


def render_png(entries):
    assets = []
    for entry in entries:
        text = (OUTPUT / entry["svg"]).read_bytes()
        assets.append({"id": entry["id"], "width": entry["width"],
                       "height": entry["height"],
                       "svg": base64.b64encode(text).decode("ascii")})
    payload = json.dumps(assets)
    result = browser("<!doctype html><meta charset='utf-8'><pre id='result'></pre>"
                     + "<script>const assets=" + payload + ";" + """
Promise.all(assets.map(async a => {
  const image = new Image();
  image.src = 'data:image/svg+xml;base64,' + a.svg;
  await image.decode();
  const canvas = document.createElement('canvas');
  canvas.width = Math.ceil(a.width); canvas.height = Math.ceil(a.height);
  const ctx = canvas.getContext('2d');
  ctx.imageSmoothingEnabled = false;
  ctx.drawImage(image, 0, 0, a.width, a.height);
  return {id:a.id, png:canvas.toDataURL('image/png').split(',')[1]};
})).then(result => {
  document.getElementById('result').textContent = JSON.stringify(result);
}).catch(error => {
  document.getElementById('result').textContent = JSON.stringify({error:String(error)});
});
</script>""")
    by_id = {entry["id"]: entry for entry in entries}
    for item in result:
        entry = by_id[item["id"]]
        data = base64.b64decode(item["png"], validate=True)
        if data[:8] != b"\x89PNG\r\n\x1a\n":
            raise ValueError(f"Invalid PNG for {entry['id']}")
        actual = struct.unpack(">II", data[16:24])
        expected = (math.ceil(entry["width"]), math.ceil(entry["height"]))
        if actual != expected:
            raise ValueError(f"PNG size mismatch: {entry['id']}: {actual} != {expected}")
        path = Path(entry["svg"]).with_suffix(".png")
        (OUTPUT / path).write_bytes(data)
        entry["png"] = path.as_posix()
        entry["png_size"] = list(actual)
        entry["png_sha256"] = hashlib.sha256(data).hexdigest()


def preview(entries):
    cards = []
    for entry in entries:
        cards.append(
            '<article><div class="image"><img src="'
            + html.escape(entry["png"]) + '" alt=""></div><strong>'
            + html.escape(entry["name"]) + '</strong><p>'
            + html.escape(entry["id"]) + ' · '
            + str(entry["width"]) + ' × ' + str(entry["height"])
            + '</p><a href="' + html.escape(entry["svg"]) + '">SVG</a> · '
            + '<a href="' + html.escape(entry["png"]) + '">PNG</a></article>'
        )
    document = """<!doctype html><html lang="en"><meta charset="utf-8">
<title>Windows 95 UI Kit — asset catalog</title><style>
body{font:14px system-ui;background:#008080;color:#fff;margin:24px}
main{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:16px}
article{background:#c0c0c0;color:#000;padding:12px;border:2px outset #fff;overflow:auto}
.image{height:120px;display:flex;align-items:center;justify-content:center;
background:repeating-conic-gradient(#ddd 0% 25%,#eee 0% 50%) 0 0/16px 16px;margin-bottom:12px}
img{image-rendering:pixelated;max-width:100%;max-height:116px;object-fit:contain}
p{color:#333;font-size:12px}a{color:#000080}
</style><h1>Windows 95 UI Kit</h1><p>Native-size PNG + isolated SVG. Original Figma node IDs retained.</p><main>"""
    (OUTPUT / "index.html").write_text(document + "".join(cards) + "</main></html>", encoding="utf-8")


def contact_sheet(entries):
    assets = [{"label": "/".join(e["figma_path"][1:] or e["figma_path"]),
               "width": e["width"], "height": e["height"],
               "png": base64.b64encode((OUTPUT / e["png"]).read_bytes()).decode()}
              for e in entries if e["kind"] == "component"]
    images_html = "".join('<img hidden src="data:image/png;base64,' + a["png"] + '">' for a in assets)
    result = browser("<!doctype html>" + images_html + "<pre id='result'></pre><script>const assets="
                     + json.dumps(assets) + ";" + """
window.addEventListener('load', () => { try {
  const canvas = document.createElement('canvas');
  canvas.width = 1400; canvas.height = Math.ceil(assets.length/7)*136;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#008080'; ctx.fillRect(0,0,canvas.width,canvas.height);
  ctx.imageSmoothingEnabled = false;
  const images=[...document.querySelectorAll('img')];
  for (let i=0;i<assets.length;i++) {
    const a=assets[i], x=(i%7)*200, y=Math.floor(i/7)*136;
    ctx.fillStyle='#c0c0c0'; ctx.fillRect(x+2,y+2,196,132);
    const image=images[i];
    const scale=Math.min(2,192/a.width,94/a.height);
    const w=a.width*scale, h=a.height*scale;
    ctx.drawImage(image,x+100-w/2,y+50-h/2,w,h);
    ctx.fillStyle='#000'; ctx.font='10px monospace';
    const label=a.label.replaceAll('State=','').replaceAll('Type=','');
    ctx.fillText(label.slice(0,31),x+6,y+111);
    ctx.fillText(label.slice(31,62),x+6,y+124);
  }
  document.getElementById('result').textContent=JSON.stringify(
    {png:canvas.toDataURL('image/png').split(',')[1]});
} catch(e) {document.getElementById('result').textContent=JSON.stringify({error:String(e)});}});
</script>""")
    (OUTPUT / "preview.png").write_bytes(base64.b64decode(result["png"], validate=True))


def validate():
    manifest = json.loads((OUTPUT / "manifest.json").read_text(encoding="utf-8"))
    entries = manifest["assets"]
    ids = [entry["id"] for entry in entries]
    if len(ids) != len(set(ids)):
        raise ValueError("Duplicate Figma IDs in manifest")
    for entry in entries:
        for format_name in ("svg", "png"):
            data = (OUTPUT / entry[format_name]).read_bytes()
            if hashlib.sha256(data).hexdigest() != entry[f"{format_name}_sha256"]:
                raise ValueError(f"Checksum mismatch: {entry[format_name]}")
        svg = ET.parse(OUTPUT / entry["svg"]).getroot()
        defined = {n.attrib["id"] for n in svg.iter() if "id" in n.attrib}
        if references(svg) - defined:
            raise ValueError(f"Unresolved SVG references: {entry['id']}")
        for node in svg.iter():
            for key, value in node.attrib.items():
                if key.endswith("href") and not value.startswith(("#", "data:")):
                    raise ValueError(f"External SVG dependency: {entry['id']}")
    assets = [{"id": e["id"], "png": base64.b64encode((OUTPUT / e["png"]).read_bytes()).decode()}
              for e in entries]
    images_html = "".join('<img hidden src="data:image/png;base64,' + a["png"] + '">' for a in assets)
    report = browser("<!doctype html>" + images_html + "<pre id='result'></pre><script>const assets="
                     + json.dumps(assets) + ";" + """
window.addEventListener('load',()=>{try {
const images=[...document.querySelectorAll('img')];
const report=assets.map((a,index)=>{
  const image=images[index];
  const canvas=document.createElement('canvas');
  canvas.width=image.naturalWidth; canvas.height=image.naturalHeight;
  const ctx=canvas.getContext('2d'); ctx.drawImage(image,0,0);
  const pixels=ctx.getImageData(0,0,canvas.width,canvas.height).data;
  let visible=0, transparent=0;
  for(let i=3;i<pixels.length;i+=4) {
    if(pixels[i]) visible++;
    if(pixels[i]===0) transparent++;
  }
  return {id:a.id,visible,transparent,width:canvas.width,height:canvas.height};
});document.getElementById('result').textContent=JSON.stringify(report);
}catch(e){document.getElementById('result').textContent=JSON.stringify({error:String(e)});}});
</script>""")
    for item in report:
        if not item["visible"]:
            raise ValueError(f"Blank PNG: {item['id']}")
    icon_ids = {e["id"] for e in entries if e["figma_path"][0] == "Icons" and e["kind"] == "component"}
    if any(not item["transparent"] for item in report if item["id"] in icon_ids):
        raise ValueError("Icon background is not transparent")
    print(json.dumps({"verified_assets": len(entries), "component_ids": manifest["component_count"],
                      "reference_ids": manifest["reference_count"], "transparent_icons": len(icon_ids),
                      "checks": ["unique IDs", "SHA-256", "self-contained SVG",
                                 "PNG decode", "nonempty pixels", "icon transparency"]}, indent=2))


def package():
    path = OUTPUT.parent / "windows95-ui-kit.zip"
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for asset in sorted(OUTPUT.rglob("*")):
            if asset.is_file() and not asset.name.endswith(".import"):
                archive.write(asset, Path("windows95") / asset.relative_to(OUTPUT))
    print(f"Archive: {path} ({path.stat().st_size} bytes)")


def export():
    inventory = json.loads((Path(__file__).with_name("windows95-nodes.json")).read_text())
    source_path = OUTPUT / "_source/components.svg"
    if not source_path.exists() and (OUTPUT / "source.svg").exists():
        source_path.parent.mkdir(parents=True, exist_ok=True)
        (OUTPUT / "source.svg").rename(source_path)
    source_text = source_path.read_text(encoding="utf-8")
    texts = {"page": source_text}
    for path in (OUTPUT / "_source").glob("board-*.svg"):
        texts[path.stem.removeprefix("board-").replace("-", ":")] = path.read_text(encoding="utf-8")
    trees = {key: ET.fromstring(text) for key, text in texts.items()}
    bounds = group_bounds(texts)
    scale = float(trees["page"].attrib["width"]) / inventory["page_width"]
    origin_x, origin_y = inventory["page_origin"]
    entries = []
    for kind in ("components", "boards"):
        for node_id, names, x, y, width, height in inventory[kind]:
            board = next((b for b in inventory["boards"]
                          if x >= b[2] and y >= b[3]
                          and x + width <= b[2] + b[4] + 0.01
                          and y + height <= b[3] + b[5] + 0.01
                          and b[1][0] == names[0]), None)
            source_key = board[0] if board and board[0] in texts else "page"
            if source_key == "page":
                crop = ((x - origin_x) * scale, (y - origin_y) * scale,
                        width * scale, height * scale)
                tolerance = 3 * scale
            else:
                crop = (x - board[2], y - board[3], width, height)
                tolerance = 3
            group = select_group(bounds[source_key], names[-1], crop, tolerance)
            svg_text = isolate(trees[source_key], group["id"], crop, (width, height))
            category = "references" if kind == "boards" else slug(names[0])
            filename = "--".join(slug(name) for name in names[1:] or names)
            relative = Path(category) / (filename + "--" + node_id.replace(":", "-") + ".svg")
            (OUTPUT / relative).parent.mkdir(parents=True, exist_ok=True)
            (OUTPUT / relative).write_bytes(svg_text.encode("utf-8"))
            entries.append({"id": node_id, "name": names[-1], "figma_path": names,
                            "kind": "component" if kind == "components" else "reference",
                            "width": width, "height": height, "svg": relative.as_posix(),
                            "svg_group": group["id"], "source_export": source_key,
                            "svg_sha256": hashlib.sha256(svg_text.encode()).hexdigest()})
    render_png(entries)
    manifest = {
        "file_key": inventory["file_key"], "page_id": inventory["page_id"],
        "source_url": "https://www.figma.com/design/" + inventory["file_key"],
        "export_method": "Figma MCP SVG exports; isolated groups; Chromium PNG rasterization at original dimensions",
        "component_count": len(inventory["components"]),
        "reference_count": len(inventory["boards"]), "assets": entries,
    }
    (OUTPUT / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    palette = [names[0] for _, names, *_ in inventory["boards"] if names[0].startswith("#")]
    (OUTPUT / "palette.json").write_text(json.dumps(palette, indent=2) + "\n")
    preview([entry for entry in entries if entry["kind"] == "component"])
    contact_sheet(entries)
    validate()
    package()
    print(json.dumps({"components": manifest["component_count"],
                      "references": manifest["reference_count"],
                      "svg_files": len(entries), "png_files": len(entries),
                      "output": str(OUTPUT)}, indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fetch-board", nargs=2, metavar=("NODE_ID", "URL"))
    parser.add_argument("--verify", action="store_true")
    parser.add_argument("--package", action="store_true")
    args = parser.parse_args()
    if args.fetch_board:
        node_id, url = args.fetch_board
        if not re.fullmatch(r"\d+:\d+", node_id):
            parser.error("NODE_ID must have Figma's numeric ID format")
        directory = OUTPUT / "_source"
        directory.mkdir(parents=True, exist_ok=True)
        request = urllib.request.Request(url, headers={"User-Agent": "Windows95AssetExporter/1.0"})
        with urllib.request.urlopen(request, timeout=60) as response:
            data = response.read()
        ET.fromstring(data)
        (directory / f"board-{node_id.replace(':', '-')}.svg").write_bytes(data)
        print(f"Saved board {node_id}: {len(data)} bytes")
    elif args.verify:
        validate()
    elif args.package:
        package()
    else:
        export()


if __name__ == "__main__":
    main()
