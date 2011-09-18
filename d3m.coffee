class D3M
  constructor:
    (@context, @width=320, @height=320) ->
  d3dist:
    (x,y=0,z=0) -> Math.sqrt(x*x+y*y+z*z)
  d3rotate:
    (x0,y0,va) -> 
      x: x0 * Math.cos(va) - y0 * Math.sin(va)
      y: x0 * Math.sin(va) + y0 * Math.cos(va)
  d3vrotate:
    (x0,y0,z0,vx,vy,vz,va) ->
      r = @d3dist(vx,vy,vz)
      ax = vx/r
      ay = vy/r
      az = vz/r
      sin = Math.sin(va)
      cos = Math.cos(va)
      l_cos = 1.0 - cos
      return {
        x: (ax*ax*l_cos+cos)*x0 + (ax*ay*l_cos-az*sin)*y0 + (az*ax*l_cos-ax*sin)*z0
        y: (ax*ay*l_cos+az*sin)*x0 + (ay*ay*l_cos+cos)*y0 + (ay*az*l_cos-ax*sin)*z0
        z: (az*ax*l_cos-ay*sin)*x0 + (ay*az*l_cos+ax*sin)*y0 + (az*az*l_cos+cos)*z0
      }
  d3setlocal:
    (LGmpx=0,LGmpy=0,LGmpz=0, LGm00=1,LGm10=0,LGm20=0, LGm01=0,LGm11=1,LGm21=0, LGm02=0,LGm12=0,LGm22=1) ->
      # 座標変換演算用マトリクス設定 (Local->Global Matrix と Global->Screen Matrix を合成演算)
      @LGSm00 = @GSm00*LGm00 + @GSm10*LGm01
      @LGSm10 = @GSm00*LGm10 + @GSm10*LGm11
      @LGSm20 = @GSm00*LGm20 + @GSm10*LGm21
      @LGSmpx = @GSm00*LGmpx + @GSm10*LGmpy + @GSmpx

      @LGSm01 = @GSm01*LGm00 + @GSm11*LGm01 + @GSm21*LGm02
      @LGSm11 = @GSm01*LGm10 + @GSm11*LGm11 + @GSm21*LGm12
      @LGSm21 = @GSm01*LGm20 + @GSm11*LGm21 + @GSm21*LGm22
      @LGSmpy = @GSm01*LGmpx + @GSm11*LGmpy + @GSm21*LGmpz + @GSmpy

      @LGSm02 = @GSm02*LGm00 + @GSm12*LGm01 + @GSm22*LGm02
      @LGSm12 = @GSm02*LGm10 + @GSm12*LGm11 + @GSm22*LGm12
      @LGSm22 = @GSm02*LGm20 + @GSm12*LGm21 + @GSm22*LGm22
      @LGSmpz = @GSm02*LGmpx + @GSm12*LGmpy + @GSm22*LGmpz + @GSmpz
      return
  d3setcam:
    (cpx=0, cpy=0, cpz=0, ppx=0, ppy=0, ppz=0, ppv=1) ->
      @wincx = @width / 2
      @wincy = @height / 2

      # カメラ方向三角比計算
      ax = cpx - ppx
      ay = cpy - ppy
      az = cpz - ppz

      r0 = Math.sqrt(ax*ax + ay*ay)
      r1 = Math.sqrt(r0*r0 + az*az)
      if r0 isnt 0.0
        cos0 = -ax / r0
        sin0 = -ay / r0
      if r1 isnt 0.0
        cos1 = r0 / r1
        sin1 = az / r1

      # グローバル座標 → スクリーン座標 変換マトリクス
      az = ppv / (0.01 + @height) # 視野角

      @GSm00 = sin0
      @GSm10 = -cos0
      @GSm01 = cos0*cos1*az
      @GSm11 =  sin0*cos1*az
      @GSm21 = -sin1*az
      @GSm02 = cos0*sin1
      @GSm12 =  sin0*sin1
      @GSm22 =  cos1

      @GSmpx = -(@GSm00*cpx + @GSm10*cpy)
      @GSmpy = -(@GSm01*cpx + @GSm11*cpy + @GSm21*cpz)
      @GSmpz = -(@GSm02*cpx + @GSm12*cpy + @GSm22*cpz)

      # 座標変換演算用マトリクス設定 (Global->Screen Matrix で初期化)
      @d3setlocal 0,0,0, 1,0,0, 0,1,0, 0,0,1
      return
  d3trans:
    (x,y,z) ->
      @dz = @LGSm01*x + @LGSm11*y + @LGSm21*z + @LGSmpy
      @df = false
      if @dz > 0
        @dx = @wincx + (@LGSm00*x + @LGSm10*y + @LGSm20*z + @LGSmpx) / @dz
        @dy = @wincy - (@LGSm02*x + @LGSm12*y + @LGSm22*z + @LGSmpz) / @dz
        @df = @dx < 8000 and @dy < 8000
      return
  d3vpos:
    (x,y,z) ->
      [@ex, @ey, @ef] = [@dx, @dy, @df]
      @d3trans x,y,z
      return
  d3getpos:
    (x,y,z) ->
      @d3vpos x,y,z
      if @df
        return {x:@dx, y:@dy}
      return null
  d3pos:
    (x,y,z) ->
      @d3vpos x,y,z
      if @df 
        @context.moveTo(@dx, @dy)
      return
  d3initlineto:
    ->
      @df = false
      return
  d3pset:
    (x=0,y=0,z=0) ->
      throw 'unsupported operation'
  d3lineto:
    (x=0,y=0,z=0) ->
      @d3vpos x, y, z
      if @df
        @context.lineTo @dx, @dy
  d3line:
    (ppx=0,ppy=0,ppz=0, ssx=0,ssy=0,ssz=0) ->
      @d3vpos ssx,ssy,ssz
      @d3vpos ppx,ppy,ppz

      if @df and @ef
        @context.moveTo @ex,@ey
        @context.lineTo @dx,@dy
        return

      if @df or @ef
        if @df
          @context.moveTo @dx,@dy
          [ax,ay,az] = [ppx,ppy,ppz]
          [bx,bY,bz] = [ssx,ssy,ssz]
        else
          @context.moveTo @ex,@ey
          [ax,ay,az] = [ssx,ssy,ssz]
          [bx,bY,bz] = [ppx,ppy,ppz]
        for cnt in [0..9]
          cx = (ax + bx) / 2
          cy = (ay + bY) / 2
          cz = (az + bz) / 2
          @d3trans cx,cy,cz
          if @df
            [ax,ay,az] = [cx,cy,cz]
            @context.lineTo @ex,@ey
          else
            [bx,bY,bz] = [cx,cy,cz]
      return
  d3arrow:
    (x1,y1,z1, x2,y2,z2) ->
      @d3line x1,y1,z1, x2,y2,z2
      if @df and @ef
        a = Math.atan2(@dy-@ey, @dx-@ex)
        @d3vpos (x1*6+x2)/7, (y1*6+y2)/7, (z1*6+z2)/7
        r = @d3dist(x1-x2, y1-y2, z1-z2)/@dz/25
        bx = Math.cos(a) * r
        bY = Math.sin(a) * r
        @context.moveTo @dx - bY, @dy + bx
        @context.lineTo @ex, @ey
        @context.lineTo @dx + bY, @dy - bx
      return
  d3box:
    (v11,v12,v13, v14,v15,v16) ->
      @d3line v11, v12, v13,  v11, v12, v16
      @d3line v11, v12, v16,  v11, v15, v16
      @d3line v11, v15, v16,  v11, v15, v13
      @d3line v11, v15, v13,  v11, v12, v13

      @d3line v14, v12, v13,  v14, v15, v13
      @d3line v14, v15, v13,  v14, v15, v16
      @d3line v14, v15, v16,  v14, v12, v16
      @d3line v14, v12, v16,  v14, v12, v13

      @d3line v11, v12, v13,  v14, v12, v13
      @d3line v11, v12, v16,  v14, v12, v16
      @d3line v11, v15, v16,  v14, v15, v16
      @d3line v11, v15, v13,  v14, v15, v13
      return
  d3circle:
    (x,y,z, r, flg) ->
      @d3vpos x,y,z
      if @df
        r = r/@dz
        @context.moveTo @dx+r,@dy
        @context.arc @dx,@dy,r,0,Math.PI*2,false
      return
  d3mes:
    (s, x,y,z) ->
      @d3vpos x,y,z
      if @df
        metrics = @context.measureText(s)
        # TODO 文字列の高さをあらかじめ測定し、指定された座標を中心とした文字列の描画を可能にする
        @context.strokeText(s, @dx-metrics.width/2, @dy)
      return    
