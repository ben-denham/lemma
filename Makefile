BASE_IMAGE_NAME=lemma

# Building and dependencies
env:
	echo "BASE_IMAGE_NAME=${BASE_IMAGE_NAME}" > .env
build: env
	docker-compose build \
		--build-arg GROUP_ID=`id -g` \
		--build-arg USER_ID=`id -u`
deps: build
	docker-compose run --rm  --workdir="/home/jovyan" jupyter \
		pip install --user -e "lemma[dev]"
clear-build:
	docker-compose rm
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml rm

# Running the application
run: deps
	docker-compose up
stop:
	docker-compose stop

# Starting a shell in a Docker container
bash:
	docker-compose exec jupyter /bin/bash
sudo-bash:
	docker-compose exec --user root jupyter /bin/bash
run-bash:
	docker-compose run --rm jupyter /bin/bash
run-sudo-bash:
	docker-compose run --user root --rm jupyter /bin/bash

# Python module utilities
lint:
	docker-compose run --rm --workdir="/home/jovyan/lemma" jupyter flake8 .
test:
	docker-compose run --rm --workdir="/home/jovyan/lemma" jupyter \
		pytest \
		--cov="lemma" \
		--cov-report="html:test/coverage" \
		--cov-report=term
