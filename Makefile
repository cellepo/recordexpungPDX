.PHONY: clean

STACK_NAME := recordexpungpdx
DB_CONTAINER_NAME := db
BACKEND_CONTAINER_NAME := expungeservice
FRONTEND_CONTAINER_NAME := webserver
REQUIREMENTS_TXT := src/backend/requirements.txt
OSFLAG 	:=
ifeq ($(OS),Windows_NT)
	OSFLAG = WIN32
endif


clean:
ifeq ($(OSFLAG), WIN32)
	del /s /q /f .\src\backend\*.egg-info -and \
	del /s /q /f .\*pyc -and \
	del /s /q /f .\*~
else
	rm -rf src/backend/*.egg-info &
	find . -type f -name \*~ | xargs rm &
	find . -type f -name \*pyc | xargs rm
endif

dev: dev_up

dev_up:
	docker-compose -f docker-compose.dev.yml up -d

dev_down:
	docker-compose -f docker-compose.dev.yml down

dev_build:
	docker-compose -f docker-compose.dev.yml build

dev_logs:
	docker-compose -f docker-compose.dev.yml logs -f

dev_psql:
	docker exec -ti $(shell docker ps -qf name=$(DB_CONTAINER_NAME)) psql -U postgres -d record_expunge # TODO: Extract db name from config/expungeservice/expungeservice.env

bash_backend:
	docker exec -it $(shell docker ps -qf name=$(BACKEND_CONTAINER_NAME)) /bin/bash

bash_frontend:
	docker exec -it $(shell docker ps -qf name=$(FRONTEND_CONTAINER_NAME)) /bin/bash

database_image:
	docker build --no-cache -t $(STACK_NAME):database config/postgres -f config/postgres/Dockerfile.dev

expungeservice_image:
	docker build --no-cache -t $(STACK_NAME):expungeservice src/backend/ -f src/backend/Dockerfile.dev

dblogs:
	docker logs --details -ft $(shell docker ps -qf name=$(DB_CONTAINER_NAME))

applogs:
	docker logs --details -ft $(shell docker ps -qf name=$(BACKEND_CONTAINER_NAME))

weblogs:
	docker logs --details -ft $(shell docker ps -qf name=$(FRONTEND_CONTAINER_NAME))

dev_test:
	docker exec -t $(shell docker ps -qf name=$(BACKEND_CONTAINER_NAME)) mypy
	docker exec -t $(shell docker ps -qf name=$(BACKEND_CONTAINER_NAME)) pytest

dev_drop_database:
	docker volume rm $(shell docker volume ls -qf name=$(STACK_NAME))

dev_mock_oeci_up:
	docker-compose -f docker-compose.dev.yml -f src/frontend/developerUtils/docker-compose.mock-oeci.yml up -d

deploy: deploy_backend deploy_frontend

.ONESHELL:
deploy_update_repo:
	cd ~/recordexpungPDX/
	git reset --hard
	git checkout master
	git pull origin master

.ONESHELL:
deploy_backend: deploy_update_repo
	cd ~/recordexpungPDX/src/backend/
	killall uwsgi
	$(shell tr '\n' ' ' < ~/recordexpungPDX/config/expungeservice/expungeservice.production.env) nohup pipenv run uwsgi --socket 127.0.0.1:3031 --module expungeservice.wsgi &

.ONESHELL:
deploy_frontend: deploy_update_repo
	cd ~/recordexpungPDX/src/frontend/
	npm run build
	cp -r build/* /usr/share/nginx/html/

.PHONY: $(REQUIREMENTS_TXT)
$(REQUIREMENTS_TXT):
	pipenv lock -r > $@
