Shader "Custom/warp-shader" {
    Properties{
        _TimeSeries_1("TimeSeries_1", Range(0, 10)) = 1.725
        _TimeSeries_2("TimeSeries_2", Range(0, 10)) = 1.725
        _TimeSeries_3("TimeSeries_3", Range(0, 10)) = 1.725
    }
    SubShader{
        Tags{ "RenderType" = "Opaque" }
        LOD 200
        Pass{
        CGPROGRAM
        #pragma vertex vert_img
        #pragma fragment frag

        #include "UnityCG.cginc"
        
        float _TimeSeries_1;
        float _TimeSeries_2;
        float _TimeSeries_3;
        
        fixed2 hash(fixed2 p) {
            p = fixed2(dot(p, fixed2(127.1, 311.7)), dot(p, fixed2(269.5, 183.3)));
            return -1.0 + 2.0 * frac(sin(p)*43758.5453123);
        }
        
        float noise(in fixed2 p)
        {
            static const float K1 = 0.366025404;
            static const float K2 = 0.211324865;

            fixed2 i = floor(p + (p.x + p.y)*K1);

            fixed2 a = p - i + (i.x + i.y)*K2;
            fixed2 o = (a.x > a.y) ? fixed2(1.0, 0.0) : fixed2(0.0, 1.0);
            fixed2 b = a - o + K2;
            fixed2 c = a - 1.0 + 2.0*K2;

            fixed3 h = max(0.5 - fixed3(dot(a, a), dot(b, b), dot(c, c)), 0.0);

            fixed3 n = h*h*h*h*fixed3(dot(a, hash(i + 0.0)), dot(b, hash(i + o)), dot(c, hash(i + 1.0)));
            return dot(n, fixed3(70.0, 70.0, 70.0));
        }

        static const float2x2 m = float2x2(0.80,  -0.60, 0.60,  0.80);
        
        float fbm4(in fixed2 p)
        {
            float f = 0.0;
            f += 0.5000*noise(p);
            p = mul(p,m)*2.02;
            f += 0.2500*noise(p); 
            p = mul(p, m)*2.03;
            f += 0.1250*noise(p);
            p = mul(p, m)*2.01;
            //p = mul(p, m)*_TimeSeries_1;
            f += 0.0625*noise(p);
            return f;
        }
        
        float fbm6(in fixed2 p)
        {
            float f = 0.0;
            f += 0.5000*noise(p);
            p = mul(p, m)*2.02;
            f += 0.2500*noise(p);
            p = mul(p, m)*2.03;
            f += 0.1250*noise(p);
            p = mul(p, m)*2.01;
            f += 0.0625*noise(p);
            p = mul(p, m)*2.04;
            f += 0.031250*noise(p);
            //p = mul(p, m)*2.01;
            p = mul(p, m)*_TimeSeries_1;
            f += 0.015625*noise(p);
            return f;
        }

        float turb4(in fixed2 p)
        {
            float f = 0.0;
            f += 0.5000*abs(noise(p)); p = mul(p, m)*2.02;
            f += 0.2500*abs(noise(p)); p = mul(p, m)*2.03;
            //f += 0.1250*abs(noise(p)); p = mul(p, m)*2.01;
            f += 0.1250*abs(noise(p)); p = mul(p, m)*_TimeSeries_1;
            f += 0.0625*abs(noise(p));
            return f;
        }
        
        float turb6(in fixed2 p)
        {
            float f = 0.0;
            f += 0.5000*abs(noise(p)); p = mul(p, m)*2.02;
            f += 0.2500*abs(noise(p)); p = mul(p, m)*2.03;
            f += 0.1250*abs(noise(p)); p = mul(p, m)*2.01;
            f += 0.0625*abs(noise(p)); p = mul(p, m)*2.04;
            //f += 0.031250*abs(noise(p)); p = mul(p, m)*2.01;
            f += 0.031250*abs(noise(p)); p = mul(p, m)*_TimeSeries_1;
            f += 0.015625*abs(noise(p));
            return f;
        }

        float marble(in fixed2 p)
        {
            return cos(p.x + fbm4(p));
        }

        float wood(in fixed2 p)
        {
            float n = noise(p);
            return n - floor(n);
        }

        float dowarp(in fixed2 q, out fixed2 a, out fixed2 b)
        {
            float ang = 0.;
            ang = 1.2345 * sin(0.015*_Time.y);
            //ang = 1.2345 * sin(0.015*_Time.y) * _TimeSeries_1;
            float2x2 m1 = float2x2(cos(ang), sin(ang), -sin(ang), cos(ang));
            ang = 0.2345 * sin(0.021*_Time.y);
            //ang = 0.2345 * sin(0.021*_Time.y) * _TimeSeries_1;
            float2x2 m2 = float2x2(cos(ang), sin(ang), -sin(ang), cos(ang));

            a = fixed2(marble(mul(q,m1)), marble(mul(q,m2) + fixed2(1.12, 0.654)));

            ang = 0.543 * cos(0.011*_Time.y * -_TimeSeries_2);
            m1 = float2x2(cos(ang), sin(ang), -sin(ang), cos(ang));
            ang = 1.128 * cos(0.018*_Time.y * -_TimeSeries_3);
            m2 = float2x2(cos(ang), sin(ang), -sin(ang), cos(ang));

            //b = fixed2(marble(m2*(q + a)), marble(m1*(q + a)));
            b = fixed2(marble(mul((q+a),m2)), marble((mul((q + a), m1))));

            return marble(q + b + fixed2(0.32, 1.654));
        }

        fixed4 frag(v2f_img i) : SV_Target
        {

            fixed2 uv = (i.uv*_ScreenParams.xy) / _ScreenParams.xy;
            fixed2 q = 2.*uv - 1.;
            q.y = mul(q.y, (_ScreenParams.y / _ScreenParams.x));

            float Time = 0.1*_Time.y;
            //q += fixed2(4.0*sin(Time), 0.);
            q += fixed2(4.0*sin(0), 0.);
            //q *= 1.725;
            //q = mul(q, 1.725);
            q = mul(q, 5);
            //q = mul(q, _TimeSeries_1);

            fixed2 a = fixed2(0., 0.);
            fixed2 b = fixed2(0., 0.);
            float f = dowarp(q, a, b);
            f = 0.5 + 0.5*f;

            fixed3 col = fixed3(f, f, f);
            float c = 0.;
            c = f;
            col = fixed3(c, c*c, c*c*c);
            c = abs(a.x);
            col -= fixed3(c*c, c, c*c*c);
            c = abs(b.x);
            col += fixed3(c*c*c+(_TimeSeries_1 * 0.025f), c*c-(_TimeSeries_2 * 0.025f), c-(_TimeSeries_3 * 0.025f));
            //col *= 0.7;
            //col = mul(col, 0.7);
            col = mul(col, 0.7);
            col.x = pow(col.x, 2.18);
            //  col.y = pow(col.y, 1.58);
            col.z = pow(col.z, 1.88);
            col = smoothstep(0., 1., col);
            col = 0.5 - (1.4*col - 0.7)*(1.4*col - 0.7);
            col = 1.25*sqrt(col);
            col = clamp(col, 0., 1.);

            // Vignetting
            //fixed2 r = -1.0 + 2.0*(uv);
            //float vb = max(abs(r.x), abs(r.y));
            //col *= (0.15 + 0.85*(1.0 - exp(-(1.0 - vb)*30.0)));
            //col = mul(col, 0.15 + 0.85*(1.0 - exp(-(1.0 - vb)*30.0)));
            //fragColor = vec4(col, 1.0);
            return fixed4(col.x, col.y, col.z, 1.0);

        }
        ENDCG
        }
    }
    FallBack "Diffuse"
}
