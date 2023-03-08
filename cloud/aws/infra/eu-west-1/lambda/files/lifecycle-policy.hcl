{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire images exceeding count",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 20
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
