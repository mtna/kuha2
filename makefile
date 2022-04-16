# Default image makefile (soft linked from image directory)
# https://www.tutorialspoint.com/makefile/
#

# MACROS
tag = latest

# Default build
build:
	docker build -t mtna/$(notdir $(CURDIR)):$(tag) .

# Publish to DockerHub
hub:
	docker push mtna/$(notdir $(CURDIR)):$(tag)
