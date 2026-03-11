COMPOSE_FILE = srcs/docker-compose.yml

up:
	docker compose -f $(COMPOSE_FILE) up --build -d

down:
	docker compose -f $(COMPOSE_FILE) down

clean:
	docker compose -f $(COMPOSE_FILE) down -v --remove-orphans

fclean: clean
	docker image prune -af 

re: fclean up