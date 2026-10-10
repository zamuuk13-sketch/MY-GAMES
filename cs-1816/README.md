# CS-1816

Protótipo de FPS tático em Godot 4.7, com mapa de deserto original inspirado no ritmo de mapas de bombsite clássicos. O layout não replica Dust2: ele usa rotas próprias, duas áreas de objetivo e coberturas simples.

## Como abrir
1. Baixe ou clone o repositório.
2. Abra a pasta `cs-1816` no Godot 4.7 ou mais recente.
3. Execute `Menu.tscn` (ou pressione F6 no projeto aberto para testar uma cena específica).

## Controles
- WASD: movimentar
- Mouse: olhar
- Espaço: pular
- Esc: liberar/recapturar o mouse

## Primeira versão
- Layout blockout 3D com corredores, pátios, paredes e coberturas.
- Jogador em primeira pessoa com colisão e gravidade.
- Geometria simples para facilitar a expansão e otimização.
- Materiais com textura procedural de ruído para quebrar superfícies uniformes.
- Caixas com faixas metálicas, fachadas, janelas, canos e luminárias.
- Escadas e patamares nas rotas laterais.
- Marcações visuais pintadas para as zonas de plantio A e B.
- Placas 3D de orientação e coberturas adicionais.
- Menu principal com entrada para jogar e configurações.
- Editor de mira com prévia ao vivo, cor personalizada, tamanho, espaçamento, espessura, opacidade, ponto, contorno e modo estático/dinâmico.
- Configurações da mira salvas localmente e aplicadas à mira durante a partida.
- Seleção de equipe antes da partida, com pontos de spawn e objetivos diferentes para ataque e defesa.
- Perfis de mira predefinidos e perfil personalizado salvo localmente.
- Próximas etapas: bomba plantável/desarmável, armas, bots, rounds e HUD completo.
