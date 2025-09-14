resource "aws_ecs_cluster" "this" {
  name = "audiobook-cluster"
}

resource "aws_lb" "alb" {
  name = "audiobook-alb"
  internal = false
  load_balancer_type = "application"
  subnets = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "tg" {
  name = "audiobook-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  target_type = "ip"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port = 80
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_ecs_task_definition" "app" {
  family = "audiobook-task"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "512"
  memory = "1024"
  execution_role_arn = aws_iam_role.ecs_exec_role.arn
  task_role_arn = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name = "backend"
      image = "${aws_ecr_repository.app.repository_url}:latest"
      essential = true
      portMappings = [{ containerPort = 8000, hostPort = 8000, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group" = "/ecs/audiobook"
          "awslogs-region" = var.aws_region
          "awslogs-stream-prefix" = "backend"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "app" {
  name = "audiobook-service"
  cluster = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count = 1
  launch_type = "FARGATE"
  network_configuration {
    subnets = aws_subnet.public[*].id
    security_groups = [aws_security_group.alb_allow.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name = "backend"
    container_port = 8000
  }
  depends_on = [aws_lb_listener.http]
}

resource "aws_security_group" "alb_allow" {
  name        = "alb-allow-sg"
  description = "Allow HTTP inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

