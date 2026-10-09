import subprocess
import urllib.parse

password = urllib.parse.quote('Elpescado22a*')
project_ref = 'ptfefcqyjwfeaymedgnu'

regions = [
    'aws-0-us-east-1.pooler.supabase.com',
    'aws-0-us-west-1.pooler.supabase.com',
    'aws-0-sa-east-1.pooler.supabase.com',
    'aws-0-eu-central-1.pooler.supabase.com',
    'aws-0-ap-southeast-1.pooler.supabase.com',
    'aws-0-eu-west-1.pooler.supabase.com',
    'aws-0-ap-northeast-1.pooler.supabase.com',
]

for region in regions:
    url = f"postgres://postgres.{project_ref}:{password}@{region}:6543/postgres"
    print(f"Testing region {region}...")
    cmd = f'npx -y supabase db query --db-url "{url}" "SELECT 1;"'
    res = subprocess.run(cmd, capture_output=True, text=True, shell=True)
    if "SELECT 1" in res.stdout or res.returncode == 0:
        print(f"✅ SUCCESS on region: {region}!")
        # Apply full schema file
        cmd_schema = f'npx -y supabase db query --db-url "{url}" -f "supabase/schema.sql"'
        res_schema = subprocess.run(cmd_schema, capture_output=True, text=True, shell=True)
        print("SCHEMA OUTPUT:\n", res_schema.stdout)
        print("SCHEMA ERRORS:\n", res_schema.stderr)
        break
    else:
        print(f"Failed on {region}: {res.stderr.strip() or res.stdout.strip()}")
