Shader "Wdx/ShaderBook/NormalMapWorldSpace"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "white" { }
        _BumpMap ("Normal Map", 2D) = "bump" { }//bump对应了模型自带的法线纹理
        _BumpScale ("Bump Scale", Float) = 1.0
        _Specular ("Specular Color ", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }

    SubShader
    {
        Pass
        {
            Tags
            {
                "LightingMode" = "ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment  frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;//纹理名+ST 
            float4 _MainTex_ST;//xy存储缩放值 zw存储偏移值
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT; //需要用tangent.w分量来决定切线空间中的第三个坐标轴——副切线的方向性
                float4 texcoord : TEXCOORD0;

            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;//使用了2张纹理，因此我们需要存储两张纹理坐标，于是float2变float4
                float4 TtoW0:TEXCOORD1 ;
                float4 TtoW1:TEXCOORD2 ;
                float4 TtoW2:TEXCOORD3 ;
            };

            v2f vert(a2v v)
            {
                v2f f;

                f.pos = UnityObjectToClipPos(v.vertex);

                f.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                f.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                //float3 binormal=cross(normalize(v.normal),normalize(v.tangent.xyz))*v.tangent.w;//tangent.w分量决定方向
                //float3x3 rotation=float3x3(v.tangent.xyz,binormal,v.normal);
                
                float3 worldPos=mul(unity_ObjectToWorld,v.vertex);

                fixed3 worldNormal=UnityObjectToWorldNormal(v.normal);

                fixed3 worldTangent=UnityObjectToWorldDir(v.tangent.xyz);

                fixed3 binormal=cross(worldNormal,worldTangent)*v.tangent.w;//w分量来决定切线空间中的第三个坐标轴的方向

                //一个插值寄存器最多只能存储float4大小的变量，对于矩阵这样的变量，可把它们按行拆成多个变量进行存储
                //变换是需要使用3X3大小的矩阵，将世界空间下的顶点位置存储到变量的w分量中以充分利用插值寄存器

                f.TtoW0=float4(worldTangent.x,binormal.x,worldNormal.x,worldPos.x);

                f.TtoW1=float4(worldTangent.y,binormal.y,worldNormal.y,worldPos.y); 

                f.TtoW2=float4(worldTangent.z,binormal.z,worldNormal.z,worldPos.z);

                return f;
            }

            fixed4 frag(v2f f) : SV_Target
            {

                float3 worldPos=float3(f.TtoW0.w,f.TtoW1.w,f.TtoW2.w);

                fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(worldPos));

                fixed3 worldViewDir=normalize(UnityWorldSpaceViewDir(worldPos));

                fixed4 packedNormal = tex2D(_BumpMap, f.uv.zw);//颜色值

                fixed3 tangentNormal;
                //如果法线贴图没有设置为Normap map    
                //piexl=(normal+1)/2   normal=pixel*2-1
                //tangentNormal.xy=(packedNormal.xy*2-1)*_BumpScale;
                //tangentNormal.z=sqrt(1.0-saturate(dot(tangentNormal.xy,tangentNormal.xy)));
                //
                tangentNormal = UnpackNormal(packedNormal);

                // tangentNormal.xy *= _BumpScale;
                // tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy))); //这两步UnpackNormal()函数已经帮我们做好
                tangentNormal.xy*=_BumpScale;

                fixed3 worldTangentNormal=normalize(half3(dot(f.TtoW0,tangentNormal),dot(f.TtoW1,tangentNormal),dot(f.TtoW2,tangentNormal)));          

                float3 albedo = tex2D(_MainTex, f.uv.xy).rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * (dot(worldTangentNormal, worldLightDir) * 0.5 + 0.5);

                fixed3 halfDir = normalize(worldLightDir + worldViewDir);

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldTangentNormal,halfDir)), _Gloss);

                fixed3 color = ambient + diffuse + specular;

                return fixed4(color, 1);
            }

            ENDCG
        }
    }

    FallBack "Specular"
}