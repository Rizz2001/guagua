import subprocess
import urllib.parse

password = urllib.parse.quote('Elpescado22a*')
project_ref = 'ptfefcqyjwfeaymedgnu'
region = 'aws-0-us-east-2.pooler.supabase.com'

print(f"Targeting exact region {region} (us-east-2 Ohio)...")

for port in [6543, 5432]:
    for user in [f"postgres.{project_ref}", "postgres"]:
        url = f"postgres://{user}:{password}@{region}:{port}/postgres"
        print(f"Attempting migration on {user}@{region}:{port}...")
        cmd = f'npx -y supabase db query --db-url "{url}" -f "supabase/schema.sql"'
        res = subprocess.run(cmd, capture_output=True, text=True, shell=True)
        out = res.stdout.strip()
        err = res.stderr.strip()
        print("STDOUT:\n", out)
        print("STDERR:\n", err)
        if res.returncode == 0 and "Error" not in out and "FATAL" not in err:
            print("SUCCESS! DB Migration Complete!")
            exit(0)
