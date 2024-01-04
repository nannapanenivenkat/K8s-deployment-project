resource "aws_instance" "monitoring_server" {
  ami                    = "ami-0c7217cdde317cfec"   #change ami id for different region
  instance_type          = "t2.medium"
  key_name               = "mynewkey"
  vpc_security_group_ids = [aws_default_security_group.default_sg.id]
  subnet_id = aws_subnet.main.id

  tags = {
    Name = "Monitoring-server"
  }

  root_block_device {
    volume_size = 15
  }
}
