COMPOSE_DIR=srcs

.PHONY: build up down logs clean

build:
	@echo "Building all images..."
	cd $(COMPOSE_DIR) && docker compose build --parallel

up:
	@echo "Starting stack (detached)..."
	cd $(COMPOSE_DIR) && docker compose up -d

down:
	@echo "Stopping stack..."
	cd $(COMPOSE_DIR) && docker compose down

logs:
	cd $(COMPOSE_DIR) && docker compose logs -f

clean:
	@echo "Removing volumes (data persistence will be deleted).";
	cd $(COMPOSE_DIR) && docker compose down -v --remove-orphans

