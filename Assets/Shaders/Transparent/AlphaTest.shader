Shader "Wdx/ShaderBook/AlphaTest"
{
    Properties
    {
        _Color ("Main Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "white" { }
        //_Cutoff参数用于决定我们调用clip进行透明度测试时使用的判定条件。它的范围是[0，1]
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags
        {
            "Queue" = "AlphaTest"
            //指明该Shader不受投影器的影响
            "IgnoreProjector" = "True"
            //着色器分类
            "RenderType" = "TransparentCutout"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Cutoff;

            struct a2f
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(a2f v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);

                fixed3 worldLightDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                fixed4 texColor = tex2D(_MainTex, i.uv);

                //Alpha Test
                clip(texColor.a - _Cutoff);
                //Equal to

                //if(texColor.a-_Cutoff)<0.0
                //{ 
                //		discard
                //}
                fixed3 albedo = texColor.rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal, worldLightDir));

                fixed3 color = ambient + diffuse;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }

    FallBack "Transparent/Cutout/VertexLit"
}