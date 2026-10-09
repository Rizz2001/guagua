import subprocess
import urllib.parse

password = urllib.parse.quote('Elpescado22a*')
project_ref = 'ptfefcqyjwfeaymedgnu'

regions = [
    'aws-0-sa-east-1.pooler.supabase.com',
    'aws-0-us-east-1.pooler.supabase.com',
    'aws-0-us-west-1.pooler.supabase.com',
    'aws-0-eu-central-1.pooler.supabase.com',
    'aws-0-ap-southeast-1.pooler.supabase.com'
]

for region in regions:
    for port in [5432, 6543]:
        url = f"postgres://postgres.{project_ref}:{password}@{region}:{port}/postgres"
        cmd = f'npx -y supabase db query --db-url "{url}" -f "supabase/schema.sql"'
        print(f"Testing {region}:{port}...")
        res = subprocess.run(cmd, capture_output=True, text=True, shell=True)
        out = res.stdout.strip()
        err = res.stderr.strip()
        print(f"Result {region}:{port} -> stdout: '{out}' | stderr: '{err}'")
        if res.returncode == 0 and "tenant/user" not in err and "ENOTFOUND" not in err:
            print(f"🎉 SUCCESS ON {region}:{port}!")
            exit(0)
