# Sigma Parkour

Protótipo 3D de parkour feito em Godot 4.x.

## Primeira etapa: mapa-base
- Base e plataformas azuis com colisões físicas.
- Percurso com saltos, plataformas elevadas, blocos de treino e parede baixa.
- Céu azul procedural e nuvens volumétricas estilizadas feitas com malhas leves.
- Luz solar direcional com sombras e iluminação ambiente.
- Marcador `PlayerSpawn` reservado para integrar o personagem FBX e a animação Idle na próxima etapa.

## Abrir
Abra esta pasta como projeto no Godot e execute `Main.tscn` (F6) ou o projeto (F5).

## Próximas etapas
1. Confirmar escala, rig e orientação do personagem FBX.
2. Importar e ligar `Breathing Idle.fbx` ao esqueleto compatível do personagem.
3. Substituir a câmera de pré-visualização por câmera de acompanhamento.
4. Implementar movimentação e parkour com colisões testadas.

O mapa atual é um greybox inicial: os obstáculos são blocos simples para validar escala e percurso antes de adicionar arte final.
