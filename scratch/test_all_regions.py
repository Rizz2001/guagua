import subprocess
import urllib.parse

password = urllib.parse.quote('Elpescado22a*')
project_ref = 'ptfefcqyjwfeaymedgnu'

all_regions = [
    'aws-0-us-east-1.pooler.supabase.com',
    'aws-0-us-east-2.pooler.supabase.com',
    'aws-0-us-west-1.pooler.supabase.com',
    'aws-0-us-west-2.pooler.supabase.com',
    'aws-0-ca-central-1.pooler.supabase.com',
    'aws-0-sa-east-1.pooler.supabase.com',
    'aws-0-eu-west-1.pooler.supabase.com',
    'aws-0-eu-west-2.pooler.supabase.com',
    'aws-0-eu-west-3.pooler.supabase.com',
    'aws-0-eu-central-1.pooler.supabase.com',
    'aws-0-eu-north-1.pooler.supabase.com',
    'aws-0-ap-south-1.pooler.supabase.com',
    'aws-0-ap-southeast-1.pooler.supabase.com',
    'aws-0-ap-southeast-2.pooler.supabase.com',
    'aws-0-ap-northeast-1.pooler.supabase.com',
    'aws-0-ap-northeast-2.pooler.supabase.com',
]

for region in all_regions:
    for user in [f"postgres.{project_ref}", "postgres"]:
        for port in [6543, 5432]:
            url = f"postgres://{user}:{password}@{region}:{port}/postgres"
            cmd = f'npx -y supabase db query --db-url "{url}" "SELECT 1;"'
            res = subprocess.run(cmd, capture_output=True, text=True, shell=True)
            out = res.stdout.strip()
            err = res.stderr.strip()
            if "tenant/user" not in out and "ENOTFOUND" not in out and "Error" not in out and res.returncode == 0:
                print(f"🎉 FOUND REGION & USER: {region} | {user} | {port}")
                # Execute full schema migration
                cmd_schema = f'npx -y supabase db query --db-url "{url}" -f "supabase/schema.sql"'
                res_schema = subprocess.run(cmd_schema, capture_output=True, text=True, shell=True)
                print("SCHEMA RESULT:\n", res_schema.stdout)
                print("SCHEMA ERRORS:\n", res_schema.stderr)
                exit(0)
            else:
                if "tenant/user" not in out and "ENOTFOUND" not in out:
                    print(f"Match candidate {region} ({user}:{port}): {out or err}")

print("Search completed.")
