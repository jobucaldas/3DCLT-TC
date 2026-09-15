# Tech Challenge 3

Grupo:

- Gabriel Espanguero Gonzalez (RM 370713) - @gabriegonza no discord
- João Victor Bueno de Caldas (RM 372873) - @jobue no discord

Repos:
- [3DCLT](https://github.com/jobucaldas/3DCLT-TC/tree/t3)
- [analytics-service](https://github.com/jobucaldas/analytics-service/tree/t3)
- [auth-service](https://github.com/jobucaldas/auth-service/tree/t3)
- [evaluation-service](https://github.com/jobucaldas/evaluation-service/tree/t3)
- [flag-service](https://github.com/jobucaldas/flag-service/tree/t3)
- [targeting-service](https://github.com/jobucaldas/targeting-service/tree/t3)

Vídeo:[https://youtu.be/iMdWhg4UhBo](https://www.youtube.com/watch?v=-ntulwAAzas)

Observações: 

- Escolhemos o cloudflare r2 para ser independente da aplicação e poder mudar de conta com mais facilidade.
- Aplicamos o terraform em camadas para o ArgoCD subir apenas com o cluster em pé, mas ainda automaticamente.
- Adicionamos steps no CI para preencher os secrets criados pelo terraform de forma procedural.

Custo durante o periodo de realização do trabalho: 
<img width="2559" height="1269" alt="image" src="https://github.com/user-attachments/assets/bb566857-5cc9-41b4-8cc7-b154634b4f50" />
