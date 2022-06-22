maximize
obj: 0.5 w + 2 x + 3 y_1_ + 3 y_2_ + 1 z_a + 1 z_1_ + 1 z_2_ + 1 z_3_ + 1 z_4_ + 1 z_5_ + 5 d
subject to
y_con: 1 y_1_ + 1 y_2_ >= 5
c1: 1 z_a + 2 z_1_ + 2 z_2_ + 2 z_3_ + 2 z_4_ + 2 z_5_ >= 3
z_con: 1 y_1_ + 1 y_2_ + 1 z_1_ + 1 z_2_ + 1 z_3_ + 1 z_4_ + 1 z_5_ >= 5
Bounds
z_1_ <= 1
z_2_ <= 1
z_3_ <= 1
z_4_ <= 1
z_5_ <= 1
w >= 30
x >= 0
y_1_ >= 1
y_2_ >= 2
z_a = 25
d free
General
d
End
