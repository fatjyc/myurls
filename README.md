# Myurls

URL shortener

## Deploy your own instance using Docker
On the server/machine you want to host this, you'll first need a machine withdocker and docker-compose installed, then grap this source using git:

```bash
git clone git://github.com/fatjyc/myurls.git
```

Go into the project directory, then initialization the database and run the service

```bash
./init_db.sh
docker-compose up -d
```