BASE_IMAGE_NAME=lemma

# Building and dependencies
env:
	echo "BASE_IMAGE_NAME=${BASE_IMAGE_NAME}" > .env
build: env
	touch .pypirc
	docker-compose build \
		--build-arg GROUP_ID=`id -g` \
		--build-arg USER_ID=`id -u`
deps: build
	docker-compose run --rm --workdir="/home/jovyan" jupyter \
		pip install --user -e "lemma[dev]"
clear-build:
	docker-compose rm
	docker-compose -f docker-compose.yml rm

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
	docker-compose run --rm --workdir="/home/jovyan/lemma" jupyter pytest --cov="lemma"
cache-clear:
	docker-compose run --rm jupyter \
		python3 -Bc "import pathlib; [p.unlink() for p in pathlib.Path('.').rglob('*.py[co]')]"
	docker-compose run --rm jupyter \
		python3 -Bc "import pathlib; [p.rmdir() for p in pathlib.Path('.').rglob('__pycache__')]"

# Packaging
package:
	rm -r dist
	docker-compose run --rm jupyter \
		pip install --user --upgrade setuptools wheel twine
	docker-compose run --rm --workdir="/home/jovyan/lemma" jupyter \
		python setup.py sdist bdist_wheel
package-upload: package
	docker-compose run --rm --workdir="/home/jovyan/lemma" jupyter \
		python -m twine upload dist/*

# Documentation
update-docs:
	cp README.md docs/README.md
	docker-compose run --rm --workdir="/home/jovyan/lemma" jupyter \
		lemmadoc lemma.domain.algebra > docs/lemma.domain.algebra.md
serve-docs:
	docker-compose run -p 3000:3000 --rm --workdir="/home/jovyan/lemma/docs" jupyter python -m http.server 3000
