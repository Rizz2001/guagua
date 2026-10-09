import subprocess
import urllib.parse
import re

password = urllib.parse.quote('Elpescado22a*')
project_ref = 'ptfefcqyjwfeaymedgnu'
region = 'aws-0-us-east-2.pooler.supabase.com'
url = f"postgres://postgres.{project_ref}:{password}@{region}:5432/postgres"

print("Connected to Supabase Ohio DB! Reading schema.sql...")

with open("supabase/schema.sql", "r", encoding="utf-8") as f:
    sql_text = f.read()

# Remove C-style block comments
sql_text = re.sub(r'/\*.*?\*/', '', sql_text, flags=re.DOTALL)

# Split by semicolons while respecting DO $$ ... $$ blocks and CREATE FUNCTION $$ ... $$ blocks
statements = []
current_stmt = []
in_dollar_block = False

for line in sql_text.splitlines():
    stripped = line.strip()
    if not stripped or stripped.startswith("--"):
        continue
    
    if "$$" in line:
        # Toggle dollar block status if odd count of $$
        count = line.count("$$")
        if count % 2 != 0:
            in_dollar_block = not in_dollar_block
            
    current_stmt.append(line)
    
    if stripped.endswith(";") and not in_dollar_block:
        stmt_str = "\n".join(current_stmt).strip()
        if stmt_str:
            statements.append(stmt_str)
        current_stmt = []

if current_stmt:
    stmt_str = "\n".join(current_stmt).strip()
    if stmt_str:
        statements.append(stmt_str)

print(f"Executing {len(statements)} SQL statements individually...")

success_count = 0
for idx, stmt in enumerate(statements, start=1):
    # Escape quotes for command line
    escaped_stmt = stmt.replace('"', '\\"')
    cmd = f'npx -y supabase db query --db-url "{url}" "{escaped_stmt}"'
    res = subprocess.run(cmd, capture_output=True, text=True, shell=True)
    out = res.stdout.strip()
    err = res.stderr.strip()
    
    if res.returncode == 0 and "Error" not in out:
        success_count += 1
        print(f"[{idx}/{len(statements)}] OK")
    else:
        print(f"[{idx}/{len(statements)}] Executed: {out or err}")

print(f"\nCOMPLETED! {success_count}/{len(statements)} statements executed successfully against Supabase!")
