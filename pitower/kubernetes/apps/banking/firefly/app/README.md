# Firefly III

Manual bootstrap for now

```
psql -U postgres
CREATE ROLE firefly LOGIN PASSWORD 'supersecret';
CREATE DATABASE firefly OWNER firefly;
GRANT ALL PRIVILEGES ON DATABASE firefly TO firefly;
```