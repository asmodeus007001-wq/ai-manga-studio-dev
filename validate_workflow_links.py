"""
validate_workflow_links.py
ComfyUI workflow(JSON) 그래프 무결성 검사기.

검사 항목:
  1) 모든 노드 input의 link id가 top-level "links" 배열에 실제로 존재하는가
  2) 그 링크의 target(node,slot)이 실제로 이 input과 일치하는가
  3) origin(node,slot)이 실제로 그 노드의 output과 일치하는가
  4) 링크의 type이 origin output 및 target input의 type과 정확히 일치하는가
  5) 같은 input link id가 두 개 이상의 서로 다른 input 슬롯에서 재사용되지 않는가
  6) output의 "links" 리스트에 적힌 id들이 실제로 그 output에서 나가는 링크와 일치하는가
  7) KSampler/VAEDecode 등 필수 입력에 link가 비어있지 않은가(선택 입력 제외)

사용법: python validate_workflow_links.py <workflow.json> [<workflow2.json> ...]
종료 코드: 0 = 전부 통과, 1 = 하나 이상 오류
"""
import json, sys

REQUIRED_INPUTS = {
    "KSampler": ["model", "positive", "negative", "latent_image"],
    "VAEDecode": ["samples", "vae"],
    "VAEEncode": ["pixels", "vae"],
    "CLIPTextEncode": ["clip"],
    "SaveImage": ["images"],
}

def validate(path):
    errors = []
    with open(path, encoding="utf-8") as f:
        data = json.load(f)

    nodes = {n["id"]: n for n in data.get("nodes", [])}
    links = {l[0]: l for l in data.get("links", [])}  # id -> [id, o_id, o_slot, t_id, t_slot, type]

    seen_input_targets = set()  # (node_id, slot_idx) that already have a link claimed

    for n in nodes.values():
        ntype = n.get("type")
        inputs = n.get("inputs", [])
        for idx, inp in enumerate(inputs):
            link_id = inp.get("link")
            name = inp.get("name")
            if link_id is None:
                if ntype in REQUIRED_INPUTS and name in REQUIRED_INPUTS[ntype]:
                    errors.append(f"[{path}] node {n['id']}({ntype}) 필수 입력 '{name}' 연결 없음")
                continue
            if link_id not in links:
                errors.append(f"[{path}] node {n['id']}({ntype}) input '{name}' link {link_id} 가 links 배열에 없음")
                continue
            lid, o_id, o_slot, t_id, t_slot, ltype = links[link_id]
            if t_id != n["id"] or t_slot != idx:
                errors.append(
                    f"[{path}] link {link_id}: target이 ({t_id},slot{t_slot})인데 실제로는 node {n['id']}({ntype}) slot{idx}('{name}')에서 참조됨 — 불일치"
                )
            if ltype != inp.get("type"):
                errors.append(
                    f"[{path}] link {link_id}: 링크 타입 {ltype} != input '{name}' 타입 {inp.get('type')} (node {n['id']})"
                )
            if o_id not in nodes:
                errors.append(f"[{path}] link {link_id}: origin node {o_id} 존재하지 않음")
                continue
            onode = nodes[o_id]
            if o_slot >= len(onode.get("outputs", [])):
                errors.append(f"[{path}] link {link_id}: origin node {o_id}({onode.get('type')})에 output slot {o_slot} 없음")
                continue
            oout = onode["outputs"][o_slot]
            if oout.get("type") != ltype:
                errors.append(
                    f"[{path}] link {link_id}: origin output 타입 {oout.get('type')} != 링크 타입 {ltype} (node {o_id} slot {o_slot})"
                )
            if link_id not in (oout.get("links") or []):
                errors.append(
                    f"[{path}] link {link_id}: origin node {o_id} output slot {o_slot}의 links 리스트에 {link_id}가 없음"
                )
            key = (t_id, t_slot)
            if key in seen_input_targets:
                errors.append(f"[{path}] link {link_id}: target ({t_id},slot{t_slot})가 이미 다른 링크에서도 사용됨(같은 입력에 두 개 연결)")
            seen_input_targets.add(key)

    # cross-check: every link id in top-level array must be referenced by exactly one input
    referenced = {inp.get("link") for n in nodes.values() for inp in n.get("inputs", []) if inp.get("link") is not None}
    for lid in links:
        if lid not in referenced:
            errors.append(f"[{path}] link {lid}: 어떤 노드 입력에서도 참조되지 않는 고아 링크")

    return errors

if __name__ == "__main__":
    all_errors = []
    for p in sys.argv[1:]:
        errs = validate(p)
        if errs:
            print(f"❌ FAIL: {p}  ({len(errs)}건 오류)")
            for e in errs:
                print("   -", e)
        else:
            print(f"✅ PASS: {p}")
        all_errors += errs
    sys.exit(1 if all_errors else 0)
