# Whirlybird

* 組合語言的小組 Final Project
* 以下是當時的紀錄與程式架構

## Constant
* INITIAL_V：當玩家碰到板子時，設定的初始速度（負值）
* GRAVITY：每次更新時，影響玩家的速度（正值）
* UPPER_BOUND：約為半個螢幕高
* LOWER_BOUND：最低板子高度
* SPRING_RATE：彈簧板子倍率

## Global Variable
* height：初始為 0
    * 每次更新時，height = max(height, 玩家的 y)
    * 同時代表分數，有可能需要取整數或除以多少之類的
* gameover：初始為 false
    * 當值為 true 後結束遊戲
* board_arr：所有板子的陣列（用 LENGTHOF board_arr 控制板子數量

## 玩家
* 參數
    * x
    * y
    * v：垂直速度
* 其他
    * 當碰到板子，v = INITIAL_V
    * 每次更新時，y += v
    * 當玩家的 y >= UPPER_BOUND 或 y <= LOWER_BOUND 時
        * 玩家的 y 不再 += v
        * 取而代之，所有板子的 y -= v

## 板子
* 參數
    * x
    * y
    * kind：種類

|        板子        | kind | 簡述     | 功能                             | 機率 |
|:------------------:|:----:| -------- |:-------------------------------- |:----:|
| &#045;&#045;&#045; |  0   | 板子     |                                  |      |
|        <=>         |  1   | 移動板子 | 隨著時間改變自己的 x 值          |      |
|        ===         |  2   | 彈簧     | v = INITIAL_V * SPRING_RATE      |      |
|        III         |  3   | 破裂     | 碰到後會裂開消失，可觸發一次跳躍 |      |
| &#045;&#045;&#045; |  4   | 隱形     | 一下顯示一下消失，但其實一直都在 |      |
|        OOO         |  5   | 雲       | 碰到會直接消失，並且無法觸發跳躍 |      |
|        ^^^         |  6   | 尖刺     | 碰到後玩家爆掉，gameover = true  |      |


## 架構😢
* initialplayerPosY = 20
* 每次更新：
    1. 左右
    2. 玩家上升下降
        * if flyingStatus == 12（玩家下降）
            * if playerPos.y > 25 -> (all dec board.y)
            * else -> inc playerPos.y
            * 如果玩家撞到板子 -> flyingStatus = 0
        * else（玩家上升）
            * if playerPos.y < 15 -> (all inc board.y && inc initialplayerPosY)
            * else -> dec playerPos.y
    3. 當 board.y > 28 -> board.y = 1 (random x)
    4. score = max(score, initialplayerPosY - playerPos.y)
    5. draw board (板子需在範圍內)
    6. draw player
    7. Delay(?)
