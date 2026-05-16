NAME    := inception
LOGIN   := sgil--de
DATA    := /home/$(LOGIN)/data
COMPOSE := cd srcs && docker compose

.PHONY: all setup build up down stop start restart logs ps clean fclean re

all: up

setup:
	@mkdir -p $(DATA)/mariadb $(DATA)/wordpress
	@echo "Host data directories ready in $(DATA)"

build: setup
	@echo "Building images..."
	$(COMPOSE) build

up: build
	@echo "Starting $(NAME)..."
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

restart:
	$(COMPOSE) restart

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

clean:
	$(COMPOSE) down -v --remove-orphans

fclean: clean
	-docker system prune -af
	@rm -rf $(DATA)/mariadb $(DATA)/wordpress
	@echo "Full clean done."

re: fclean all
