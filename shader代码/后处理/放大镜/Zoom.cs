using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class Zoom : MonoBehaviour
{
    // shader
    public Shader myShader;
    //材质 
    public Material mat = null;

    // 放大强度
    [Range(-2.0f, 2.0f), Tooltip("放大强度")]
    public float zoomFactor = 0.4f;

    // 放大镜大小
    [Range(0.0f, 0.2f), Tooltip("放大镜大小")]
    public float size = 0.15f;

    // 凸镜边缘强度
    [Range(0.0001f, 0.1f), Tooltip("凸镜边缘强度")]
    public float edgeFactor = 0.05f;

    // 遮罩中心位置
    private Vector2 pos = new Vector4(0.5f, 0.5f);

    void Start()
    {
        //找到对应的Shader文件  
        myShader = Shader.Find("lcl/screenEffect/Zoom");
    }

    // 渲染屏幕
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (mat)
        {
            // 把鼠标坐标传递给Shader
            mat.SetVector("_Pos", pos);
            mat.SetFloat("_ZoomFactor", zoomFactor);
            mat.SetFloat("_EdgeFactor", edgeFactor);
            mat.SetFloat("_Size", size);
            // 渲染
            Graphics.Blit(source, destination, mat);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }

    void Update()
    {
        if (Input.GetMouseButton(0))
        {
            Vector2 mousePos = Input.mousePosition;
            //将mousePos转化为（0，1）区间
            pos = new Vector2(mousePos.x / Screen.width, mousePos.y / Screen.height);
        }
    }

}
