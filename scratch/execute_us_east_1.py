import subprocess
import urllib.parse

password = urllib.parse.quote('Elpescado22a*')
project_ref = 'ptfefcqyjwfeaymedgnu'
region = 'aws-0-us-east-1.pooler.supabase.com'

for port in [6543, 5432]:
    for user in [f"postgres.{project_ref}", "postgres"]:
        url = f"postgres://{user}:{password}@{region}:{port}/postgres"
        print(f"Executing schema on {region}:{port} with user {user}...")
        cmd = f'npx -y supabase db query --db-url "{url}" -f "supabase/schema.sql"'
        res = subprocess.run(cmd, capture_output=True, text=True, shell=True)
        print("STDOUT:\n", res.stdout.strip())
        print("STDERR:\n", res.stderr.strip())
        if res.returncode == 0:
            print("SUCCESS! DB Migration Complete!")
            break
