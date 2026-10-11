# Sigma Parkour

Protótipo 3D de parkour feito em Godot 4.x.

## O que já está preparado
- Mapa-base azul com plataformas, blocos, degraus e colisões.
- Céu procedural azul, nuvens leves e luz direcional com sombras.
- Personagem FBX carregado como player através de `PlayerController.gd`.
- Movimentação com WASD; Shift corre e Espaço salta.
- Câmera em terceira pessoa controlada pelo mouse, com suavização de acompanhamento e SpringArm para evitar atravessar paredes.
- Motion blur direcional leve durante movimentos rápidos do mouse.
- Tentativa automática de carregar as animações do `Breathing Idle.fbx` e reproduzir a animação com nome mais compatível.

## Controles
- **WASD:** mover em relação à direção da câmera.
- **Shift:** correr.
- **Espaço:** pular.
- **Mouse:** olhar ao redor.
- **Esc:** liberar o cursor; clique na janela para capturá-lo novamente.

## Abrir
Abra esta pasta como projeto no Godot e execute `Main.tscn` (F6) ou o projeto (F5). Na primeira abertura, aguarde o Godot terminar de importar os FBX.

## Nota sobre os FBX
A ligação da animação depende de o Godot importar o FBX de idle com um `AnimationPlayer` e de os nomes/caminhos dos ossos serem compatíveis com o rig de `personagem.fbx`. O controlador procura automaticamente a biblioteca de animações, mas é necessário testar no Godot para confirmar a compatibilidade do rig e ajustar a escala/orientação visual se o export original usar eixos diferentes.

O mapa e o controlador são uma primeira versão jogável para validar escala, câmera e movimento antes de implementar corrida animada, vault, wall-run e outras mecânicas de parkour.
