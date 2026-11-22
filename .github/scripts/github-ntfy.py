import os,json,sys,time
from urllib.request import Request,urlopen
e=os.environ["GITHUB_EVENT_NAME"]
p=json.load(open(os.environ["GITHUB_EVENT_PATH"]))
repo=os.environ["GITHUB_REPOSITORY"]
name=os.environ["PROJECT_LABEL"]
topic=os.environ.get("NTFY_TOPIC","")
token=os.environ.get("GH_TOKEN","")
if not topic: sys.exit("Missing NTFY_TOPIC secret")
link=f"https://github.com/{repo}"; title=name; body=""; priority=3; tags=[]; actions=[]
if e=="workflow_run":
 r=p["workflow_run"]; conclusion=r.get("conclusion") or "unknown"
 link=r.get("html_url") or link
 workflow=r.get("name") or "Workflow"
 body=f"Workflow: {workflow}\nBranch: {r.get('head_branch')}\nCommit: {(r.get('head_sha') or '')[:7]}\nResult: {conclusion}"
 found=[]
 try:
  uri=f"https://api.github.com/repos/{repo}/actions/runs/{r['id']}/artifacts?per_page=100"
  with urlopen(Request(uri,headers={"Accept":"application/vnd.github+json","Authorization":f"Bearer {token}","X-GitHub-Api-Version":"2022-11-28"}),timeout=15) as response:
   found=[a for a in json.load(response).get("artifacts",[]) if not a.get("expired")]
 except Exception as x: print(f"Artifact lookup unavailable: {type(x).__name__}")
 if found:
  body+=f"\nArtifacts ({len(found)}): "+", ".join(x["name"] for x in found[:5])
  actions.append({"action":"view","label":"View artifacts","url":link+"#artifacts"})
 if conclusion=="success":
  title=f"{name}: {'Artifacts ready' if found else 'Build passed'}"
  priority=4 if found else 3; tags=["package"] if found else ["white_check_mark"]
 elif conclusion in ("failure","timed_out","action_required"):
  title=f"{name}: {workflow} failed"; priority=5; tags=["rotating_light"]
 elif conclusion=="cancelled": title=f"{name}: {workflow} cancelled"; priority=2
 else: title=f"{name}: {workflow} {conclusion}"; priority=2
elif e=="push":
 branch=p.get("ref","").removeprefix("refs/heads/")
 link=p.get("compare") or link
 title=f"{name}: {branch} updated";body=f"Commit pushed\nBranch: {branch}\nCommit: {(p.get('after') or '')[:7]}"
 priority=2; tags=["arrow_up"]
elif e=="release":
 r=p["release"];link=r.get("html_url") or link
 title=f"{name}: New release";body="Published: "+str(r.get("name") or r.get("tag_name"))
 priority=4;tags=["rocket"]
elif e=="pull_request":
 r=p["pull_request"]
 if not r.get("merged"):sys.exit(0)
 link=r.get("html_url") or link
 title=f"{name}: PR merged";body=f"PR #{r['number']} merged into {r['base']['ref']}";tags=["twisted_rightwards_arrows"]
elif e=="workflow_dispatch":
 title=f"{name}: Notifications connected";body="GitHub Actions -> ntfy.sh test successful.";tags=["white_check_mark"]
else: sys.exit(0)
actions.append({"action":"view","label":"Open GitHub","url":link})
data=json.dumps({"topic":topic,"title":title,"message":body,"priority":priority,"tags":tags,"click":link,"actions":actions[:3]}).encode()
server=os.environ.get("NOTIFY_BASE_URL","https://ntfy.sh").rstrip("/")+"/"
for i in range(3):
 try:
  with urlopen(Request(server,data=data,headers={"Content-Type":"application/json"},method="POST"),timeout=15) as response:
   if response.status not in (200,201,202):raise RuntimeError(f"HTTP {response.status}")
  print(f"Notification delivered: {title}");break
 except Exception:
  if i==2:raise
  time.sleep(i+2)
