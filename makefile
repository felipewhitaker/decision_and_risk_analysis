.PHONY setup sample run

setup:
	@pip install poetry # FIXME should install poetry the correct way
	@poetry install
	@mkdir -p data/raw
	@poetry run kaggle datasets download -d currie32/crimes-in-chicago -p data/raw --unzip

sample:
	@mkdir data/cooked
	@poetry run python scripts/generate_sample.py

run:
	@julia --project=coverenv/ cover.jl