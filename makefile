PATH = srcs/docker-compose.yml

up:
	docker-compose -f $(PATH) up --build -d

down:
	docker-compose -f $(PATH) down

clean:
	docker-compose -f $(PATH) down -v --remove-orphans

fclean: clean
	docker image prune -af 

re: fclean up