# Dynablaster

An HTML5 remake of a childhood favorite game.

Original game pictures:
http://goo.gl/pkV943

## Status

Plans:

- Multiplayer
  - 5 player
  - p (webrtc)
- Resources (http://texturelib.com/)
- Tweens
- Monsters
- Scoring
- Campaign
- Sounds
- Music

### Open questions

Things here should be investigated further. If you read this and you remember the original game mechanics please throw me a message.

##### If a stone with a hidden powerup is blown up from two fires, but from the same explosion, then is the powerup destroyed?

Currently it is destroyed.

y\x| 1 | 2 | 3
:-:|:-:|:-:|:----:
 1 | B | . | S(P)
 2 | . | X | .
 3 | B | . | B

Chain reaction of two bombs with different firepower would make me think that it is destroyed. In the next example B1 explodes and ignites the second row from 2 to 6, so it triggers B2 also. Since B2 has bigger firepower (5), it ignites the whole second row and some cells will be on fire (F2) only because of it.

y\x| 1  | 2 | 3 | 4     | 5 | 6     | 7  | 8
:-:|:--:|:-:|:-:|:-----:|:-:|:-----:|:--:|:-:
 1 | .  | X | . | X     | . | X     | .  | X
 2 | F2 | F | F | B1(2) | F | B2(5) | F2 | F2
 3 | .  | X | . | X     | . | X     | .  | X

If later a minimal delay will be introduced for the expansion of fire then it will give answer yes to the question, but in the original game... I do not remember.

## License

MIT
